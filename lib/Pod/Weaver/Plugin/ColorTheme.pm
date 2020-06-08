package Pod::Weaver::Plugin::ColorTheme;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub weave_section {
    no strict 'refs';

    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;

        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";

        if ($package =~ /(?:\A|::)ColorThemes::/) {

            {
                local @INC = ("lib", @INC);
                require $package_pm;
            }
            my %colorthemes;
            # collect color theme modules
            {
                require Module::List;
                my $res;
                {
                    local @INC = ("lib");
                    $res = Module::List::list_modules(
                        "", {list_modules=>1});
                }
                for my $mod (keys %$res) {
                    next unless $mod =~ /(?:\A|::)ColorTheme::/;
                    $colorthemes{$mod} = \%{"$mod\::THEME"};
                }
            }

            # add POD section: COLOR THEMES
            {
                last unless keys %colorthemes;
                require Markdown::To::POD;
                my @pod;
                push @pod, "=over\n\n";
                for my $name (sort keys %colorthemes) {
                    my $theme = $colorthemes{$name};
                    push @pod, "=item * L<$name>\n\n";
                    if (defined $theme->{summary}) {
                        require String::PodQuote;
                        push @pod, String::PodQuote::pod_quote($theme->{summary}), ".\n\n";
                    }
                    if ($theme->{description}) {
                        my $pod = Markdown::To::POD::markdown_to_pod(
                            $theme->{description});
                        push @pod, $pod, "\n\n";
                    }
                }
                push @pod, "=back\n\n";
                $self->add_text_to_section(
                    $document, join("", @pod), 'COLOR THEMES',
                    {after_section => ['DESCRIPTION']},
                );
            }

            # add POD section: SEE ALSO
            {
                # XXX don't add if current See Also already mentions it
                my @pod = (
                    "L<ColorTheme> - specification\n\n",
                    "L<App::ColorThemeUtils> - CLIs\n\n",
                );
                $self->add_text_to_section(
                    $document, join('', @pod), 'SEE ALSO',
                    {after_section => ['DESCRIPTION']},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } elsif ($package =~ /^(?:\A|::)ColorTheme::/) {

            {
                local @INC = ("lib", @INC);
                require $package_pm;
            }
            my $theme = \%{"$package\::THEME"};

            # add POD section: Synopsis
            {
                my @pod;

                # example on how to use
                {
                    # XXX show required args
                    push @pod, <<"_";
To show the colors of this theme (requires L<show-color-theme-swatch>):

 % show-color-theme-swatch $name

_
                    # XXX show how to use with other apps
                }

            # add POD section: DESCRIPTION
            {
                last unless $theme->{description};
                require Markdown::To::POD;
                my @pod;
                push @pod, Markdown::To::POD::markdown_to_pod(
                    $theme->{description}), "\n\n";
                $self->add_text_to_section(
                    $document, join("", @pod), 'DESCRIPTION',
                    {ignore => 1},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } # Sah::Schema::*
    }
}

1;
# ABSTRACT: Plugin to use when building distribution which has ColorTheme::* modules

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-ColorTheme]


=head1 DESCRIPTION

This plugin is used when building a distribution which has ColorTheme::*
modules. It does the following to each F<ColorTheme::*> Perl source code:

=over

=item * Create "COLOR THEMES" POD section from list of ColorTheme::* modules in the distribution

=item * Mention some modules in See Also section

e.g. L<ColorTheme>, L<App::ColorThemeUtils>.

=back

It does the following to each F<ColorTheme::*> Perl source code:

=over

=item * Add "DESCRIPTION" POD section from theme structure's description

=back


=head1 SEE ALSO

L<ColorTheme>

L<Dist::Zilla::Plugin::ColorTheme>
