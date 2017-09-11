use strict;
use Data::Dumper;
use Test::More;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::utilities;
use Bio::KBase::kbaseenv;
use fba_tools::fba_toolsImpl;
#use KBaseReport::KBaseReportImpl;

my $tester = LocalTester->new($ENV{'KB_DEPLOYMENT_CONFIG'});
$tester->run_tests();

{
	package LocalTester;
	use strict;
	use Test::More;
    sub new {
        my ($class,$configfile) = @_;
        Bio::KBase::kbaseenv::create_context_from_client_config({
        	filename => $configfile
        });
        my $c = Bio::KBase::utilities::read_config({
        	filename => $configfile,
			service => 'fba_tools'
        });
        my $object = fba_tools::fba_toolsImpl->new();
        my $self = {
            token => Bio::KBase::utilities::token(),
            config_file => $configfile,
            config => $c->{fba_tools},
            user_id => Bio::KBase::utilities::user_id(),
            ws_client => Bio::KBase::kbaseenv::ws_client(),
            obj => $object,
            testcount => 0,
            completetestcount => 0,
            dumpoutput => 0,
            testoutput => {},
            showerrors => 1
        };
        return bless $self, $class;
    }
    sub test_harness {
		my($self,$function,$parameters,$name,$tests,$fail_to_pass,$dependency) = @_;
		$self->{testoutput}->{$name} = {
			output => undef,
			"index" => $self->{testcount},
			tests => $tests,
			command => $function,
			parameters => $parameters,
			dependency => $dependency,
			fail_to_pass => $fail_to_pass,
			pass => 1,
			function => 1,
			status => "Failed initial function test!"
		};
		$self->{testcount}++;
		if (defined($dependency) && $self->{testoutput}->{$dependency}->{function} != 1) {
			$self->{testoutput}->{$name}->{pass} = -1;
			$self->{testoutput}->{$name}->{function} = -1;
			$self->{testoutput}->{$name}->{status} = "Test skipped due to failed dependency!";
			return;
		}
		my $output;
		#eval {
			if (defined($parameters)) {
				$output = $self->{obj}->$function($parameters);
			} else {
				$output = $self->{obj}->$function();
			}
		#};
		my $errors;
		if ($@) {
			$errors = $@;
		}
		$self->{completetestcount}++;
		if (defined($output)) {
			$self->{testoutput}->{$name}->{output} = $output;
			$self->{testoutput}->{$name}->{function} = 1;
			if (defined($fail_to_pass) && $fail_to_pass == 1) {
				$self->{testoutput}->{$name}->{pass} = 0;
				$self->{testoutput}->{$name}->{status} = $name." worked, but should have failed!"; 
				ok $self->{testoutput}->{$name}->{pass} == 1, $self->{testoutput}->{$name}->{status};
			} else {
				ok 1, $name." worked as expected!";
				for (my $i=0; $i < @{$tests}; $i++) {
					$self->{completetestcount}++;
					$tests->[$i]->[2] = eval $tests->[$i]->[0];
					if ($tests->[$i]->[2] == 0) {
						$self->{testoutput}->{$name}->{pass} = 0;
						$self->{testoutput}->{$name}->{status} = $name." worked, but sub-tests failed!"; 
					}
					ok $tests->[$i]->[2] == 1, $tests->[$i]->[1];
				}
			}
		} else {
			$self->{testoutput}->{$name}->{function} = 0;
			if (defined($fail_to_pass) && $fail_to_pass == 1) {
				$self->{testoutput}->{$name}->{pass} = 1;
				$self->{testoutput}->{$name}->{status} = $name." failed as expected!";
			} else {
				$self->{testoutput}->{$name}->{pass} = 0;
				$self->{testoutput}->{$name}->{status} = $name." failed to function at all!";
			}
			ok $self->{testoutput}->{$name}->{pass} == 1, $self->{testoutput}->{$name}->{status};
			if ($self->{showerrors} && $self->{testoutput}->{$name}->{pass} == 0 && defined($errors)) {
				print "Errors:\n".$errors."\n";
			}
		}
		if ($self->{dumpoutput}) {
			print "$function output:\n".Data::Dumper->Dump([$output])."\n\n";
		}
		return $output;
	}
	sub run_tests {
		my($self) = @_;
		
		#my $wsname = "chenry:1454960620516";
		my $wsname = "mikaelacashman:narrative_1500996689101"; #testing_fba_tools (production)
		my $fbamodel = "EC.CDG.GF.FBAModel";
		my $media = "CDG.media";
		my $outputid = "Mika_test_out";	
	
		my $output = $self->test_harness("run_flux_balance_analysis",{
	        "fbamodel_id"=> $fbamodel,
	        "media_id"=> $media,
	        "target_reaction"=> "bio1",
	        "fba_output_id"=> $outputid,
	        "fva"=> 1,
	        "minimize_flux"=> 1,
	        "simulate_ko"=> 1,
	        "feature_ko_list"=> [],
	        "reaction_ko_list"=> "",
	        "custom_bound_list"=> [],
	        "media_supplement_list"=> "",
	        "expseries_id"=> undef,
	        "expression_condition"=> undef,
	        "exp_threshold_percentile"=> 0.5,
	        "exp_threshold_margin"=> 0.1,
	        "activation_coefficient"=> 0.5,
	        "max_c_uptake"=> undef,
	        "max_n_uptake"=> undef,
	        "max_p_uptake"=> undef,
	        "max_s_uptake"=> undef,
	        "max_o_uptake"=> undef,
	        workspace => $wsname
	    },"Run flux balance analysis",[],0,undef);
		
		exit;
		
	}
}
