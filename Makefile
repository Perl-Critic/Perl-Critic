.PHONY: README.md

README.md:
	cat README-prologue.md > README.md
	pod2markdown lib/Perl/Critic.pm >> README.md
