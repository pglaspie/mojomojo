#!/usr/bin/env perl
use strict;
use warnings;
# WARNING: This script will delete all the children of the page you are deleting.
use FindBin;
use lib "$FindBin::Bin/../../lib";
use MojoMojo::Schema;
use Config::JFDI;
use Term::Prompt;
my $jfdi = Config::JFDI->new(name => "MojoMojo");
my $config = $jfdi->get;
my ($dsn, $user, $pass) = @ARGV;
eval {
    if (!$dsn) {
        ($dsn, $user, $pass) =
          @{$config->{'Model::DBIC'}->{'connect_info'}};
    };
};
if($@){
    die "Your DSN line in mojomojo.conf doesn't look like a valid DSN.".
      "  Add one, or pass it on the command line.";
}
die "No valid Data Source Name (DSN).\n" if !$dsn;
$dsn =~ s/__HOME__/$FindBin::Bin\/\.\./g;

my $schema = MojoMojo::Schema->connect($dsn, $user, $pass) or 
  die "Failed to connect to database";

my $page_id = prompt('n', 'Input ID of Page to Delete:', '', '' );
if ( $page_id  == 0 ) {
    die "You must select a positive integer.\n";
}

delete_page($page_id);

=head 2 

Delete a page and all its children. Cuidado.

=cut

sub delete_page {
    my $id = shift;
    
    print "Erasing page: ";
    my $page = $schema->resultset('Page')->find( { id => $id } );
    print $page->name_orig, "\n";
    $page->delete;
    my $page_version_rs =
      $schema->resultset('PageVersion')->search( { page => $id } )->delete;
    my $content_rs =
      $schema->resultset('Content')->search( { page => $id } )->delete;
    my $attachment_rs =
      $schema->resultset('Attachment')->search( { page => $id } )->delete;
    my $comment_rs =
      $schema->resultset('Comment')->search( { page => $id } )->delete;
    my $link_rs =
      $schema->resultset('Link')
      ->search( [ { from_page => $id }, { to_page => $id } ] )->delete;
    my $role_privilege_rs =
      $schema->resultset('RolePrivilege')->search( { page => $id } )->delete;
    my $tag_rs = $schema->resultset('Tag')->search( { page => $id } )->delete;
    my $wanted_page =
      $schema->resultset('WantedPage')->search( { from_page => $id } )->delete;
    my $journal_rs =
      $schema->resultset('Journal')->search( { pageid => $id } )->delete;
    my $entry_rs =
      $schema->resultset('Entry')->search( { journal => $id } )->delete;
}

__END__

=head1 Usage

perl script/util/delete_page.pl

Then input the id (positive integer) of the page you want to delete.
This number comes from the id column of the page table.
This will delete the page and all it's children (if there are any).
Use with caution.

=cut
