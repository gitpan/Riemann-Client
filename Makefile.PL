
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Perl client for the Riemann event system",
  "AUTHOR" => "Miquel Ruiz <mruiz\@cpan.org>",
  "BUILD_REQUIRES" => {
    "String::Random" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Riemann-Client",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Riemann::Client",
  "PREREQ_PM" => {
    "Google::ProtocolBuffers" => "0.08",
    "IO::Socket::INET" => 0,
    "Moo" => 0,
    "Net::Domain" => 0
  },
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



