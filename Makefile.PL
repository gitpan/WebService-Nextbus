use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WebService::Nextbus',
    'VERSION_FROM'	=> 'Nextbus.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # None!
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Nextbus.pm', # retrieve abstract from module
       AUTHOR     => 'Peter H. Li <phli@cpan.org>') : ()),
);
