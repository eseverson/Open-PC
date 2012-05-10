#!/usr/bin/env perl

use warnings;
use strict;

use CGI;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use CGI::Session qw/-ip-match/;
use DBI;

use Template;

my $q = new CGI;
$q->import_names('R');

my $db = DBI->connect( 'DBI:mysql:competition:127.0.0.1', 'evan', 'password');
my $session = new CGI::Session("driver:MySQL", $q, {Handle=>$db});

if($R::action && $R::action eq 'logout'){
	$session->clear();
}
if($session && $session->param("u_id")){ #if session active
	my $login_q = "SELECT u_id,username,user_type,password FROM users WHERE username = ? AND password = SHA(CONCAT(?, salt))";
	my $preped = $db->prepare($login_q);
	$preped->execute($R::username,$R::password);

	my ($u_id, $username, $user_type, $password) = $preped->fetchrow_array;
	if(!$u_id) {
		warn "Bad Login";
		$session->clear();
		print $q->redirect( -URL => "/~evan/cgi-bin/login.pl?failed_login=1" );
		exit;
	}else{
		print $q->redirect( -URL => "http://192.168.1.10/~evan/cgi-bin/competition.pl" );
	}
}else{
	print $session->header(),
				$q->start_html(
					-title	=> 'Programming Competition',
					-author	=> 'ejs092020@utdallas.edu',
					-style	=> [{'src' => '/~evan/css/redmond/jquery-ui-1.8.19.custom.css'},
											{'src' => '/~evan/styles/default.css'}],
					-script => 
						[{-type => 'text/JavaScript', -src => "/~evan/js/jquery-1.7.2.min.js"},
						 {-type => 'text/JavaScript', -src => "/~evan/js/jquery-ui-1.8.19.custom.min.js"},
						 {-type => 'text/JavaScript', -src => "/~evan/scripts/login.js"}],

				);

	my $tt = new Template({
		INCLUDE_PATH => '/home/evan/public_html/cgi-bin/templates',
		INTERPOLATE => 1,
		EVAL_PERL => 1,
	}) || die "$Template::ERROR\n";

	my $vars = {
		failed => ($R::failed_login?1:0),
	};

	$tt->process('login.tt', $vars) || die $tt->error(), "\n";

	print $q->end_html;
}

$session->flush();

1;
