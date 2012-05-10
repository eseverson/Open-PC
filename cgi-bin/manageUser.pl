#!/usr/bin/env perl
#print "Status: 404 Not Found\n\n"; 
#exit 0; 
use warnings;
use strict;

use CGI;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use CGI::Session qw/-ip-match/;
use DBI;

use String::Random;

use JSON;
use Switch;

my $q = new CGI;
$q->import_names('R');

my $db = DBI->connect( 'DBI:mysql:competition:127.0.0.1', 'evan', 'password');
my $session = new CGI::Session("driver:MySQL", $q, {Handle=>$db});

my $json = JSON->new->allow_nonref;

my $actions = {
	'create_user' => \&createUser,
	'delete_user' => \&deleteUser,
	'modify_user' => \&modifyUser,
};

print "Content-Type: text/json\n\n";
if(!$session->param("u_id")){
	if($R::action eq "create_user" && $R::user_type eq '3'){
		createUser();
	}else{
		#allow creation of users from login screen
		basic_response(0, "User not logged in.");
	}
}elsif($session->param("user_type") eq '1'){
	if($R::action && $actions->{$R::action}){
		$actions->{$R::action}();
	}else{
		basic_response(0, "Invalid action specified");
	}
}else{
	basic_response(0, "User not authorized to commit this action.");
}

sub deleteUser{
	#warn "User deletion requested";
	unless ($R::u_id){
		basic_response(0, "Must provide all fields");
		return;
	}
	
	my $u_id = $R::u_id;
	
	my $delUser = "DELETE FROM users WHERE u_id = ?";
	my $preped = $db->prepare($delUser);
	my $rv = $preped->execute($u_id);
	if( !$rv || $rv == 0 ){
		basic_response(0, "User not found");
	}else{
		print $json->encode({
			statuskey => ['fail', 'success'],
			status => 1,
			message => "User deleted",
			u_id => $u_id,
		});
	}
	return;
}

sub modifyUser{
	unless($R::u_id){
		basic_response(0, "Must provide all fields");
		return;
	}
	my $user_type;
	my $u_id = $R::u_id;
	
	my $preped;
	my $type_q = "SELECT user_type FROM users WHERE u_id = ?";
	$preped = $db->prepare($type_q);
	$preped->execute($u_id);
	if($preped->rows > 0){
		$user_type = $preped->fetchrow_array;
	}else{
		basic_response(0, "User not found");
		return;
	}
	
	unless ($R::username && defined $R::password && 
						(($user_type && $user_type ne '3') || ($R::team_name && $R::school))){
		basic_response(0, "Must provide all fields");
		return;
	}
	
	
	my ($username, $password, $team_name, $school) = ($R::username, $R::password, $R::team_name, $R::school);
	


	my $saltgen = new String::Random;
	my $salt = $saltgen->randpattern("ssssssssss");

	
	if($password ne ''){
		my $modUser = "UPDATE users SET username=?, password=SHA(CONCAT(?,?)), salt=? WHERE u_id = ?";
		$preped = $db->prepare($modUser);
		$preped->execute($username, $password, $salt, $salt, $u_id);
	}else{
		my $modUser = "UPDATE users SET username=? WHERE u_id = ?";
		$preped = $db->prepare($modUser);
		$preped->execute($username, $u_id);
	}
	
	if($user_type eq '3'){
		my $modTeam = "UPDATE team SET team_name=?, school=? WHERE u_id = ?";
		$preped = $db->prepare($modTeam);
		$preped->execute($team_name, $school, $u_id);
	}
	
	if( $preped->rows == 0 ){
		basic_response(0, "User not found");
		return;
	}else{
		my $response = {
			statuskey => ['fail', 'success'], 	
			user => {
					u_id => $u_id,
					username => $username,
					team_name => $user_type eq '3'?$team_name:'-',
					school => $user_type eq '3'?$school:'-',
					user_type => $user_type,
				},
			message => "User Updated.",
		};
		print $json->encode($response);
	}
	return;
}

sub createUser {
	#warn "User creation requested";
	unless ($R::username && $R::password && $R::user_type && 
						($R::user_type ne '3' || $R::team_name && $R::school) ){
		basic_response(0, "Must provide all fields");
		return;
	}

	my $response = {
		statuskey => ['fail', 'success'], 	
	};
	
	my ($username, $password, $user_type) = ($R::username, $R::password, $R::user_type);
	my ($team_name, $school) = $R::user_type eq '3'?($R::team_name, $R::school):('','');
	
	my $saltgen = new String::Random;
	my $salt = $saltgen->randpattern("ssssssssss");
	my $getUser = "SELECT 1 FROM users WHERE username = ?";
	my $preped = $db->prepare($getUser);
	$preped->execute($username);
	my @rc = $preped->fetchrow_array;
	
	if(!@rc) {
		my $addUser = "INSERT INTO users (username,password,salt,user_type) VALUES (?,SHA(CONCAT(?,?)),?,?)";
		$preped = $db->prepare($addUser);
		$preped->execute($username, $password, $salt, $salt, $user_type);
		
		my $u_id = $db->last_insert_id(0,0,0,"u_id");
		
		if($user_type eq '3'){
			my $modTeam = "INSERT INTO team (team_name, school, u_id) VALUES (?,?,?)";
			$preped = $db->prepare($modTeam);
			$preped->execute($team_name, $school, $u_id);
		}
		
		$response->{'user'} = {
			u_id => $u_id,
			username => $username,
			team_name => $team_name,
			school => $school,
			user_type => $user_type,
		};
		$response->{'message'} = "User successfully created.";
		$response->{'status'} = 1;
	} else { #user exists
		$response->{'message'} = "Username already in use.";
		$response->{'status'} = 0;
	}
	print $json->encode($response);
	return;
}

sub basic_response{
	my ($status, $message) = @_;
	print $json->encode({
		statuskey => ['fail', 'success'],
		status => $status,
		message => $message,
	});
	return;
}

1;
