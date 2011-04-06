package Bespoke::TestUtil;

use File::Spec;
use Directory::Scratch;
use String::Random;

BEGIN {
    use Directory::Scratch;
    our $tempdir = Directory::Scratch->new();
    $tempdir->mkdir("tmp");
    $tempdir->mkdir("storage");
}

use Digest::SHA qw(sha512_hex);
use Bespoke::Config (
    storage_root => File::Spec->catdir("$tempdir", "storage"),
    storage_temp => File::Spec->catdir("$tempdir", "tmp")
);

# safety check
unless (Bespoke::Config->get('storage_root') eq File::Spec->catdir("$tempdir", "storage")) {
    die "BUG IN TEST: Bespoke::Config of override storage_root failed.";
}

unless (Bespoke::Config->get('storage_temp') eq File::Spec->catdir("$tempdir", "tmp")) {
    die "BUG IN TEST: Bespoke::Config of override storage_temp failed.";
}

sub generate_blobs {
    my($class, $blob_count) = @_;
    my @blobs;

    open(my $fh, "</dev/urandom")
        or die "Could not open /dev/urandom for reading: $!";
    binmode($fh);

    for (my $i=0; $i<$blob_count; $i++) {
        # read a random amount of random, 0-1MB
        my $size = read($fh, my $bindata, int(rand(2**20)));

        my $digest = sha512_hex($bindata);

        my $in = Bespoke::Storage::Ingest->new();
        $in->write(data => $bindata);
        my $blob = $in->finish;

        $blobs[$i] = {
            blob   => $blob,
            size   => $size,
            data   => $bindata,
            digest => $digest
        };
    }
    close $fh;

    return @blobs;
}

sub text_test_file {
    my $class = shift;

    my $scratch = Directory::Scratch->new();

    my $file = $scratch->touch("lorem_ipsum_long.txt");

    open(my $fh, "> $file")
        or die "Could not open $file for writing: $!";
    print $fh $class->lorem_ipsum_long();
    close $fh;

    return($file, '5d72542bb8ec84f50201821ec2df0fdb41df5dcc6f268a93e23a68d1d327044dad3aee40b87399caf3cc6f1b1ddb8f6661ab79569d41ea6f8ab2c2a4b2083040');
}

sub lorem_ipsum_short {
    return <<EOL;
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
EOL
}

# do not modify this - the checksum is hard-coded
# Perl's newline mangling may screw this up - cross that bridge when we come to it
# atobey@zorak ~/src/bespoke/t $ sha512sum test.txt
# 5d72542bb8ec84f50201821ec2df0fdb41df5dcc6f268a93e23a68d1d327044dad3aee40b87399caf3cc6f1b1ddb8f6661ab79569d41ea6f8ab2c2a4b2083040  test.txt
sub lorem_ipsum_long {
    return <<EOL;
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent tempus urna
sem, non euismod nisi. Vivamus ante lectus, luctus eget porta vel, porta eget
est. Fusce libero urna, porta non tristique blandit, faucibus quis orci.
Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac
turpis egestas. Vestibulum blandit, magna vitae molestie dictum, sapien elit
tristique turpis, sed egestas neque tellus nec quam. Mauris et sapien nisi, et
vulputate magna. Quisque ut egestas lacus. Nullam tristique cursus turpis, vitae
lacinia libero elementum sed. Nam ac lacus nisi, in lobortis justo. Mauris in
sodales ligula. Mauris consectetur risus ac est suscipit quis aliquam elit
gravida. In consequat ligula a tortor consequat in accumsan augue euismod. In
hac habitasse platea dictumst. Suspendisse ac euismod ligula. Maecenas rutrum
blandit turpis, in euismod nisi laoreet egestas. Vivamus mattis adipiscing
purus, sed fermentum lectus adipiscing quis.

Pellentesque iaculis, arcu ac posuere mollis, diam purus aliquam quam, sed
fermentum eros nisl pulvinar sapien. Integer sodales blandit est, pellentesque
lacinia dui cursus at. Duis at dolor eget orci luctus placerat. Nunc aliquet
mattis augue at tincidunt. Ut nisi risus, eleifend vitae rutrum vel, scelerisque
sed odio. Fusce tempus lectus sit amet nulla pretium ut pellentesque nunc
tempus. Suspendisse vulputate nunc vitae urna lobortis tincidunt. Praesent ac
quam id quam posuere tristique. Nam in nunc tellus. Mauris vel odio orci. Sed
nec nunc libero, vel placerat mi. Sed ultrices turpis sed orci varius lobortis.
Nam feugiat orci vel felis consectetur ultrices. Suspendisse convallis consequat
convallis. Nullam lacinia ultricies urna sed malesuada. Curabitur at iaculis
velit.

Sed nec rhoncus est. Morbi id tellus tempor diam tincidunt tristique vitae vitae
nisi. Integer hendrerit sodales tortor, id rhoncus sem varius ut. Fusce felis
orci, condimentum eu scelerisque et, eleifend id eros. Vestibulum et quam ac
ligula dignissim volutpat. Morbi euismod fringilla aliquet. Etiam pulvinar, nisl
vel auctor hendrerit, justo tellus ultricies orci, quis ullamcorper nulla augue
eu ante. Nulla cursus congue turpis, ut consectetur justo molestie sed.
Curabitur feugiat ultrices eros, nec malesuada magna pulvinar sed. Curabitur sit
amet purus risus, vel porttitor massa. Cras eget libero tempor sapien suscipit
tempus. Aliquam porta arcu quis purus euismod et viverra dolor molestie.
Maecenas pulvinar libero vel nibh bibendum condimentum. Suspendisse aliquet diam
non nibh eleifend porttitor. Proin pretium sem mi, et varius lectus. Fusce sed
lacus ut lorem condimentum cursus. Pellentesque turpis erat, viverra eget
imperdiet ac, placerat et lectus.

Mauris adipiscing posuere pretium. Etiam pretium hendrerit nisl quis pretium.
Duis auctor mi vitae turpis sodales pharetra. Cras congue ullamcorper imperdiet.
Pellentesque porttitor aliquam dui, pulvinar molestie neque venenatis non.
Quisque nec turpis ante. Fusce ut ornare ante. Phasellus volutpat ultricies
placerat. Phasellus et pharetra est. Vestibulum ac quam ut mauris pulvinar
pellentesque.

Phasellus eget quam vitae ligula pulvinar porta nec quis erat. Curabitur
pharetra, nunc ut scelerisque molestie, eros diam interdum lacus, at cursus orci
ipsum eget elit. Curabitur elementum nulla a mauris fermentum facilisis. Integer
eu dolor metus. Aenean vel purus nisl. Quisque aliquam commodo mi, tempus
dignissim metus molestie sit amet. Praesent volutpat pretium sollicitudin. Etiam
quis venenatis augue. Nullam fringilla, ligula in posuere interdum, arcu lacus
sodales justo, in hendrerit ipsum elit at nisl. In commodo dictum vulputate.
Aliquam vehicula nibh sed tellus accumsan rhoncus. Maecenas eu dui eu mi ornare
auctor at at turpis. Sed eget sapien est, sed venenatis risus. Praesent viverra
viverra fringilla. Aenean ut ligula vel ante mattis tincidunt tincidunt eleifend
velit. Nullam fermentum, lacus vel iaculis interdum, augue urna volutpat risus,
a fermentum libero neque in augue. In volutpat ultricies lectus ac pellentesque.
Proin est dolor, aliquam in euismod vitae, scelerisque id orci. In hac habitasse
platea dictumst. Maecenas condimentum dui ut est feugiat sed ultrices mauris
pharetra.
EOL
}

1;
