#!/usr/bin/env -S make -f
# vim:fileencoding=utf-8:foldmethod=marker

#: Install {{{
#
# The service units work in system and user scope. They are installed to systemd/system and systemd/user.
#
# You need to provide your HC_PING_KEY regardless of the install method.
#
# Install for the local user (~/.local/share)
#	make install
#	systemctl --user daemon-reload
#	systemctl --user edit healthchecks-ping@.service
#   	[Service]
#   	Environment=HC_PING_KEY=<YourKey>
#
# Install system wide
#	make install TARGET=/etc
#	systemctl daemon-reload
#	systemctl edit healthchecks-ping@.service
#   	[Service]
#   	Environment=HC_PING_KEY=<YourKey>
#
# Package for distributions
#	make install PREFIX=<PKGDIR> TARGET=/usr/lib
#
# File `Makefile.env` can be used to provide parameters or ENV vars.
#
#: }}}

# Source env from file
-include Makefile.env

#: Default settings {{{
TARGET		?= ~/.local/share
DESTDIR		:= $(addprefix $(PREFIX),$(TARGET))
.PHONY		: install uninstall uninstall(%) reload-user reload-system
.SUFFIXES	:
#: }}}

#: Install service units into DESTDIR {{{

# Create parent directories
$(DESTDIR)/systemd/system $(DESTDIR)/systemd/user:
	install --directory $(@)

# Copy system unit to DESTDIR
$(DESTDIR)/systemd/system/%: systemd/system/% | $(DESTDIR)/systemd/system
	install --mode=0644 --target-directory=$(@D) $(<)

# Create user unit as link to the system unit
$(DESTDIR)/systemd/user/%: $(DESTDIR)/systemd/system/% | $(DESTDIR)/systemd/user
	ln --symbolic --relative $(<) $(@)

# Generate make dependencies for all service units
install: $(addprefix $(DESTDIR)/, $(wildcard systemd/*/*.*))

#: }}}

#: Uninstall services files {{{
uninstall(%):
	rm -f $(addprefix $(DESTDIR)/,$(%))

uninstall: uninstall($(wildcard systemd/*/*.*))
#: }}}

#: Helper to reload service units {{{
reload-user:
	systemctl --user daemon-reload

reload-system:
	systemctl daemon-reload
#: }}}