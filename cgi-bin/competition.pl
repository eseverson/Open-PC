#!/usr/bin/env perl

use warnings;
use strict;

use CGI;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use CGI::Session qw/-ip-match/;
use DBI;
#use Switch;

use Template;
use Template::Plugin::CGI;

my $q = new CGI;
$q->import_names('R');

my $base_url = $q->url(-base => 1);

my $db = DBI->connect( 'DBI:mysql:competition:127.0.0.1', 'evan', 'password');
my $session = new CGI::Session("driver:MySQL", $q , {Handle=>$db});

my ($u_id, $username, $user_type, $password);

#attempt to login if needed
if(!$session->param("u_id")){
	#warn "No session active, try to log in and set one up\n";
	if(($R::action && $R::action ne "login") ||  !$R::username || !$R::password){
		#warn "No session active, username or password not present in request\n";
		print $q->redirect( -URL => "$base_url/cgi-bin/login.pl" );
		exit;
	}
	
	my $login_q = "SELECT u_id,username,user_type,password FROM users WHERE username = ? AND password = SHA(CONCAT(?, salt))";
	my $preped = $db->prepare($login_q);
	$preped->execute($R::username,$R::password);

	($u_id, $username, $user_type, $password) = $preped->fetchrow_array;
	if(!$u_id) {
		warn "Bad Login";
		$session->clear();
		#$session->flush();
		print $q->redirect( -URL => "$base_url/cgi-bin/login.pl?failed_login=1" );
		exit;
	}else {
		#setup session
		warn "Good login, setting up session\n";
		$session->clear();
		$session->expire('10y');
		$session->param(password=>$password, user_type=>$user_type, u_id=>$u_id,);
	}
}else{
	#active session found
	my $session_q = "SELECT u_id,username,user_type,password FROM users WHERE u_id = ?";
	my $preped = $db->prepare($session_q);
	$preped->execute($session->param('u_id'));
	($u_id, $username, $user_type, $password) = $preped->fetchrow_array;	
	
	#check to make sure password has not changed since session was created
	if($password ne $session->param("password")){
		warn "Password changed since session initilization, expiring session.";
		$session->expire();
		$session->flush();
		print $q->redirect( -URL => "$base_url/cgi-bin/login.pl" );
		exit;
	}
}
	
#my $user = $session->param("username");
#my $type = $session->param("user_type");

sub getUsers {
	my $getUsrs = "SELECT users.u_id,username,team_name,school,user_type ". 
									"FROM users LEFT JOIN team ON users.u_id=team.u_id ". 
									"ORDER BY users.u_id ";
	my $preped = $db->prepare($getUsrs);
	$preped->execute();
	return $preped->fetchall_arrayref( {} );
}

sub getProblems {
	if($user_type eq '3'){
		my $getProbs = "SELECT problem.p_id,name,max(s.judgement),count(s.judgement) ".
									 "FROM problem LEFT JOIN ".
											"(SELECT p_id,judgement FROM submission WHERE submission.u_id=?) s ".
										"ON problem.p_id=s.p_id ".
										"GROUP BY problem.p_id ".
										"ORDER BY problem.p_id";
		my $preped = $db->prepare($getProbs);
		$preped->execute($u_id);
		return $preped->fetchall_arrayref( {} );
	}else{
		my $getProbs = "SELECT p_id,name FROM problem ORDER BY p_id";
		my $preped = $db->prepare($getProbs);
		$preped->execute();
		return $preped->fetchall_arrayref( {} );
	}
}

sub getSubmissions {
	if($user_type eq '3'){
		my $getProbs = "SELECT submission_time,s_id,p.p_id,name,judgement ".
									 "FROM problem p JOIN ".
									 "(SELECT submission_time,s_id,p_id,judgement FROM submission WHERE submission.u_id=?) s ".
									 "ON p.p_id=s.p_id ".
									 "ORDER BY s_id";
		my $preped = $db->prepare($getProbs);
		$preped->execute($u_id);
		return $preped->fetchall_arrayref( {} );
	}else{
		my $getProbs = "SELECT submission_time,s_id,p.p_id,u.u_id,username,name,judgement ".
									 "FROM problem p JOIN submission s JOIN users u ".
										"ON p.p_id=s.p_id AND s.u_id=u.u_id ".
										"ORDER BY s_id";
		my $preped = $db->prepare($getProbs);
		$preped->execute();
		return $preped->fetchall_arrayref( {} );
	}
}

sub getClarifications {
	return 0;
}

sub getScoreboard {
	my $getScore = "SELECT ps.u_id, ps.username, team.team_name, team.school, ps.p_id, ps.tries, ps.best, r.solved, r.submits FROM 
    (SELECT up.u_id,name,username,up.p_id,s_id,count(judgement) AS tries,max(judgement) AS best FROM 
     (SELECT * FROM problem p INNER JOIN 
      (SELECT users.u_id,username FROM users WHERE user_type='3') u) up 
    LEFT JOIN submission s ON s.p_id=up.p_id AND s.u_id=up.u_id GROUP BY up.u_id,up.p_id) ps 
      LEFT JOIN (SELECT u_id, SUM(IF(s.best=100,1,0)) AS solved, SUM(numSubs) AS submits FROM 
        (SELECT u_id,p_id,count(*) AS numSubs,max(judgement) AS best FROM submission GROUP BY u_id,p_id) s GROUP BY u_id) r 
          ON ps.u_id=r.u_id 
            JOIN team ON team.u_id=ps.u_id ORDER BY solved DESC, submits, ps.u_id, ps.p_id;";
	
	my $preped = $db->prepare($getScore);
	$preped->execute();
	return $preped->fetchall_arrayref( {} );

}

print $session->header();

print $q->start_html(
				-title	=> 'Programming Competition',
				-author	=> 'ejs092020@utdallas.edu',
				-style	=> [{'src' => "$base_url/css/redmond/jquery-ui-1.8.19.custom.css"},
										{'src' => "$base_url/styles/default.css"}],
				-script => 
				[{-type => 'text/JavaScript', -src => "$base_url/js/jquery-1.7.2.min.js"},
				 {-type => 'text/JavaScript', -src => "$base_url/js/jquery-ui-1.8.19.custom.min.js"},
				 {-type => 'text/JavaScript', -src => "$base_url/js/jquery.cookie.js"},
				 {-type => 'text/JavaScript', -src => "$base_url/scripts/competition.js"}],
);
							
my $tt = new Template({
	INCLUDE_PATH => './templates',
	INTERPOLATE => 1,
	EVAL_PERL => 1,
}) || die "$Template::ERROR\n";

my $problems = getProblems();
my $numProbs = scalar(@{$problems});

my $getUserCount = "SELECT count(*) FROM users WHERE user_type='3'";
my $preped = $db->prepare($getUserCount);
$preped->execute();
my ($userCount) = $preped->fetchrow_array;

my $scores = getScoreboard();
my ($count, $rank, $lastSolved) = (0,1,-1);
my $lastId=-1;

foreach my $s (@{$scores}){
	if($lastId ne $s->{'u_id'}){
		$lastId = $s->{'u_id'};
		$count++;
	}
	if( ($lastSolved && $s->{'solved'} && $lastSolved > $s->{'solved'}) || ($lastSolved && !$s->{'solved'}) ){
		$rank = $count;
	}
	$lastSolved = $s->{'solved'};
	$s->{'rank'} = $rank;
}

my $vars = {
	type => $user_type,
	user => $username,
	users => getUsers(),
	problems => $problems,
	numProbs => $numProbs,
	userCount => $userCount,
	clarifications => getClarifications(),
	submissions => getSubmissions(),
	scoreboard => $scores,
};

$tt->process('tabs.tt', $vars) || die $tt->error(), "\n";

print $q->end_html;

$session->flush();

1;
