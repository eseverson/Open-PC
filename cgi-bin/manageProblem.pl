#!/usr/bin/env perl
#print "Status: 404 Not Found\n\n"; 
#exit 0; 
use warnings;
use strict;

use CGI;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;
use CGI::Session qw/-ip-match/;
use DBI;

use File::Path qw(remove_tree);
use IPC::Open2;
use IPC::Open3;
	
use JSON;
use Switch;

my $q = new CGI;
$q->import_names('R');

my $db = DBI->connect( 'DBI:mysql:competition:127.0.0.1', 'evan', 'password');
my $session = new CGI::Session("driver:MySQL", $q, {Handle=>$db});

my $json = JSON->new->allow_nonref;

my $actions = {
		'1'=> {
			'create_problem' => \&createProblem,
			'delete_problem' => \&deleteProblem,
			'modify_problem' => \&modifyProblem,
			'show_problem' => \&showProblem,
			'clear_submissions' => \&clearSubs,
			'delete_sub' => \&deleteSub,
		},
		'2'=>{
			'show_problem' => \&showProblem,
		},
		'3'=>{
			'submit_problem' => \&submitProblem,
		}};
		
my $judgements = {
	'0' => "Not Yet Judged",
	'10' => "Compile Error",
	'20' => "Runtime Error",
	'30' => "Time Limit Exceeded",
	'40' => "Wrong Answer",
	'100' => "Accepted",
};

print "Content-Type: text/json\n\n";
#print "Content-Type: text/plain\n\n";
if(!$session->param("u_id")){
	basic_response(0, "User not logged in.");
}elsif($session->param("user_type")){
	if($R::action && $actions->{$session->param("user_type")}->{$R::action}){
		$actions->{$session->param("user_type")}->{$R::action}();
	}else{
		basic_response(0, "Invalid action specified " . ($R::action?$R::action:''));
	}
}else{
	basic_response(0, "User not authorized to commit this action.");
}

sub clearSubs {
	my $clearSubs = "DELETE FROM submission;";
	my $preped = $db->prepare($clearSubs);
	$preped->execute();
	system("rm -rf ../filestore/submissions/*");
	
	basic_response(1, "Submissions cleared");
	return;
}

sub deleteSub {
	unless($R::s_id){
		basic_response(0, "Submission not specified.");
		return;
	}
	
	my ($s_id) = ($R::s_id);
	
	my $hasSub = "SELECT 1 FROM submission WHERE s_id=?;";
	my $preped = $db->prepare($hasSub);
	$preped->execute($s_id);
	my @rc = $preped->fetchrow_array;
	
	if(@rc){
		my $clearSubs = "DELETE FROM submission WHERE s_id=?;";
		$preped = $db->prepare($clearSubs);
		$preped->execute($s_id);
		
		remove_tree("../filestore/submissions/$s_id");
		my $response = {
			statuskey => ['fail', 'success'], 	
			status => 1,
			message => "Submissions deleted",
			s_id => $s_id,
		};
		
		print $json->encode($response);
		return;
	}else{
		basic_response(0, "Submission not found.");
	}
}

sub submitProblem{
	unless ($R::p_id && $R::source_file){
		basic_response(0, "Must provide all fields");
		return;
	}
	my ($p_id, $source_file) = ($R::p_id, $R::source_file);
	
	my $hasSolved = "SELECT 1 FROM submission WHERE p_id = ? AND u_id = ? AND judgement = 100;";
	my $preped = $db->prepare($hasSolved);
	$preped->execute($p_id, $session->param("u_id"));
	if($preped->rows > 0){
		basic_response(0, "User has already solved this problem");
		return;
	}
	
	my $response = {
		statuskey => ['fail', 'success'], 	
	};
	
	my $getProblem = "SELECT name FROM problem WHERE p_id = ?";
	$preped = $db->prepare($getProblem);
	$preped->execute($p_id);
	my @rc = $preped->fetchrow_array;
	my ($problemname) = @rc;
	
	if(@rc) {
		$db->begin_work();
		my $submitProblem = "INSERT INTO submission (p_id, u_id, judgement) VALUES (?, ?, 0)";
		$preped = $db->prepare($submitProblem);
		$preped->execute($p_id, $session->param("u_id"));
		
		my $s_id = $db->last_insert_id(0,0,0,"s_id");
		
		unless(mkdir("../filestore/submissions/$s_id", 0777) &&
					 open(SOURCE, ">", "../filestore/submissions/$s_id/Main.java")){
			remove_tree("../filestore/submissions/$s_id");
			$db->rollback();
			basic_response(0, "Internal server error. Problem not submitted."); 
			return;
		};
		
		while(<$R::source_file>){print SOURCE $_;}
		close(SOURCE);

		$db->commit();
		
		#compile

		chdir("../filestore/submissions/$s_id");
		#my $null;
		#open($null, ">", File::Spec->devnull);
		my ($in, $out, $err);
		my $pid = open3($in, $out, $err, 'javac', 'Main.java');
		waitpid($pid, 0);
		
		my $exit_status = $? >> 8;
		my $judgement = '0';
		if($exit_status){
			warn "Compile error, s_id: $s_id";
			$judgement = '10';
		}else{
			#run
			open(PROB_INPUT, "<", "../filestore/problems/$p_id/input.txt") or die "Couldn't open input file.";
			
			eval{
				local $SIG{ALRM} = sub{
					die "TLE";
				};
				alarm 10;
				$pid = open3("<&PROB_INPUT", $out, $err, 'java', '-Djava.security.manager', 'Main');
				waitpid($pid, 0);
				$exit_status = $? >> 8;
				alarm 0;
			};
			close PROB_INPUT;
			
			if($@){
				die "INTERNAL ERROR" unless $@ eq "TLE";
				warn "Time limit exceeded, s_id: $s_id, pid: $pid";
				$judgement = '30';
			}elsif($exit_status){
				warn "Runtime error, s_id: $s_id";
				$judgement = '20';
			}else{
				warn "Successful run, s_id: $s_id, pid: $pid";
				open(OUTPUT, ">", "../filestore/submissions/$s_id/out.txt");
				while(<$out>){
					#strip trailing whitespace
					$_ =~ /^(.*?)\s*$/;
					print OUTPUT $1."\n";
				}
				close(OUTPUT);
				
				#diff
				warn "Diffing output, s_id: $s_id";
				
				open(ACTUAL, "<", "../filestore/submissions/$s_id/out.txt");
				open(EXPECTED, "<", "../filestore/problems/$p_id/output.txt");
				
				my $wrong_answer = 0;
				my ($a, $e);
				while(defined($a = <ACTUAL>) && defined($e = <EXPECTED>)){
					if($a ne $e){
						warn $a, $e;
						$wrong_answer = 1;
						last;
					}
				}
				if(!$wrong_answer && (<ACTUAL> || <EXPECTED>)){
					warn "Actual and expected different lengths, s_id: $s_id";
					$wrong_answer = 1;
				}
				
				close ACTUAL;
				close EXPECTED;
				
				if($wrong_answer){
					warn "Wrong answer, s_id: $s_id";
					$judgement = '40';
				}else{
					warn "Accepted, s_id: $s_id";
					$judgement = '100';
				}
				
			}

			close $out;
			close $in;
			#close $err;
		}
		
		my $updateSubmission = "UPDATE submission SET judgement=? WHERE s_id=?";
		$preped = $db->prepare($updateSubmission);
		$preped->execute($judgement, $s_id);
		
		$response->{'submission'} = {
			judgement_key => $judgements,
			s_id => $s_id,
			judgement => $judgement,
			p_id => $p_id,
			problemname => $problemname,
		};
		$response->{'message'} = "Solution successfully submitted.";
		$response->{'status'} = 1;
	} else { #Problem doesn't exist
		$response->{'message'} = "Problem does not exist.";
		$response->{'status'} = 0;
	 }
	print $json->encode($response);
	return;
}

sub deleteProblem{
	#warn "Problem deletion requested";
	unless ($R::p_id){
		basic_response(0, "No problem specified");
		return;
	}
	
	my $p_id = $R::p_id;
	
	my $delProblem = "DELETE FROM problem WHERE p_id = ?";
	my $preped = $db->prepare($delProblem);
	my $rv = $preped->execute($p_id);
	if( !$rv || $rv == 0 ){
		basic_response(0, "Problem $p_id not found");
	}else{
		remove_tree("../filestore/problems/$p_id");
		print $json->encode({
			statuskey => ['fail', 'success'],
			status => 1,
			message => "Problem deleted",
			p_id => $p_id,
		});
	}
	return;
}

sub modifyProblem{
	#die "FIXME: Modify problem not implemented";
	unless ($R::p_id && ($R::problemname || $R::problem_input || $R::problem_output)){
		basic_response(0, "Must provide fields");
		return;
	}
	
	my ($p_id, $problemname, $input_name, $output_name) = ($R::p_id, $R::problemname, $R::problem_input, $R::problem_output);
	
	my $response = {
		statuskey => ['fail', 'success'], 	
	};
	
	my $getProblem = "SELECT name FROM problem WHERE p_id = ?";
	my $preped = $db->prepare($getProblem);
	$preped->execute($p_id);
	my ($curName) = $preped->fetchrow_array;
	
	if($curName) {
		$db->begin_work();
		if($problemname && $curName ne $problemname){
			my $addProblem = "UPDATE problem SET name=? WHERE p_id=?";
			$preped = $db->prepare($addProblem);
			$preped->execute($problemname, $p_id);
		}
		
		my ($INPUT, $OUTPUT);
		
		unless((!$input_name || open($INPUT, ">", "../filestore/problems/$p_id/_input.txt"))&& 
					 (!$output_name || open($OUTPUT, ">", "../filestore/problems/$p_id/_output.txt"))){
			close(INPUT);
			close(OUTPUT);
			#rm _input and _output
			$db->rollback();
			basic_response(0, "Internal server error. Problem not updated"); 
			return;
		};
		
		if($INPUT){
			while(<$R::problem_input>){print $INPUT $_;}
			close($INPUT);
			rename("../filestore/problems/$p_id/_input.txt","../filestore/problems/$p_id/input.txt");
		}
		if($OUTPUT){
			while(<$R::problem_output>){
				#strip trailing whitespace
				$_ =~ /^(.*?)\s*$/;
				print $OUTPUT $1."\n";
			}
			close($OUTPUT);
			rename("../filestore/problems/$p_id/_output.txt","../filestore/problems/$p_id/output.txt");
		}
		
		$db->commit();
		
		$response->{'problem'} = {
			p_id => $p_id,
			problemname => $problemname?$problemname:$curName,
		};
		$response->{'message'} = "Problem successfully updated.";
		$response->{'status'} = 1;
	} else { #Problem name exists
		basic_response(0, "Problem not found");
		return;
	}
	print $json->encode($response);
	return;
}

sub createProblem {
	#warn "Problem creation requested";
	unless ($R::problemname && $R::problem_input && $R::problem_output){
		basic_response(0, "Must provide all fields");
		return;
	}
	
	my ($problemname, $input_name, $output_name) = ($R::problemname, $R::problem_input, $R::problem_output);
	
	my $response = {
		statuskey => ['fail', 'success'], 	
	};
	
	my $getProblem = "SELECT 1 FROM problem WHERE name = ?";
	my $preped = $db->prepare($getProblem);
	$preped->execute($problemname);
	my @rc = $preped->fetchrow_array;
	
	if(!@rc) {
		$db->begin_work();
		my $addProblem = "INSERT INTO problem (name) VALUES (?)";
		$preped = $db->prepare($addProblem);
		$preped->execute($problemname);
		
		my $p_id = $db->last_insert_id(0,0,0,"p_id");
		
		unless(mkdir("../filestore/problems/$p_id", 0777) &&
					 open(INPUT, ">", "../filestore/problems/$p_id/input.txt")&& 
					 open(OUTPUT, ">", "../filestore/problems/$p_id/output.txt")){
			close(INPUT);
			close(OUTPUT);
			remove_tree("../filestore/problems/$p_id");
			$db->rollback();
			basic_response(0, "Internal server error. Problem not added"); 
			return;
		};
		
		while(<$R::problem_input>){print INPUT $_;}
		close(INPUT);
		while(<$R::problem_output>){
					#strip trailing whitespace
					$_ =~ /^(.*?)\s*$/;
					print OUTPUT $1."\n";
		}
		close(OUTPUT);
	
		$db->commit();
		
		$response->{'problem'} = {
			p_id => $p_id,
			problemname => $problemname,
		};
		$response->{'message'} = "Problem successfully created.";
		$response->{'status'} = 1;
	} else { #Problem name exists
		$response->{'message'} = "Problem name already in use.";
		$response->{'status'} = 0;
	 }
	print $json->encode($response);
	return;
}

sub showProblem {
	#warn "Problem info requested";
	unless ($R::p_id){
		basic_response(0, "No problem specified");
		return;
	}
	
	my ($p_id) = ($R::p_id);
	
	my $response = {
		statuskey => ['fail', 'success'], 	
	};
	
	my $getProblem = "SELECT 1 FROM problem WHERE p_id = ?";
	my $preped = $db->prepare($getProblem);
	$preped->execute($p_id);
	
	if($preped->rows) {
		unless(open(INPUT, "<", "../filestore/problems/$p_id/input.txt")&& 
					 open(OUTPUT, "<", "../filestore/problems/$p_id/output.txt")){
			close(INPUT);
			close(OUTPUT);
			basic_response(0, "Internal server error."); 
			return;
		};
		my ($input, $output) = ('','');
		while(<INPUT>){$input .= $_;}
		close(INPUT);
		while(<OUTPUT>){$output .= $_;}
		close(OUTPUT);
	
		$response->{'problem'} = {
			p_id => $p_id,
			input => $input,
			output => $output,
		};
		$response->{'message'} = "";
		$response->{'status'} = 1;
	} else { #Problem name exists
		basic_response(0, "Problem not found.");
		return;
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
