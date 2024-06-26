########################################################################
# Makefile for project pipe 
# Created: Mon May 25 15:12:15 MDT 2015
#
# Pipe performs handy functions on pipe delimited files.
#    Copyright (C) 2015  Andrew Nisbet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Written by Andrew Nisbet at Edmonton Public Library
# Rev: 
#      0.0 - Dev. 
########################################################################
# Change comment below for appropriate server.
PRODUCTION_SERVER=edpl.sirsidynix.net
STAGING_SERVER=edpltest.sirsidynix.net
TEST_SERVER=edpltest.sirsidynix.net
USER=sirsi
REMOTE=~/Unicorn/Bincustom/
LOCAL=~/projects/pipe/
APP=pipe.pl
ARGS=-x
.PHONY: test production

test: ${APP}
	perl -c ${APP}
production: test 
	scp ${LOCAL}${APP} ${USER}@${STAGING_SERVER}:/software/EDPL/Unicorn/Bincustom
	scp ${LOCAL}${APP} ${USER}@${PRODUCTION_SERVER}:${REMOTE}
	scp ${LOCAL}${APP} ils@epl-ils.epl.ca:/home/ils/bin
	scp ${LOCAL}${APP} its@epl-el1.epl.ca:/home/its/bin
	scp ${LOCAL}${APP} ilsadmin@epl-olr.epl.ca:/home/ilsadmin/pipe
	scp ${LOCAL}${APP} ${USER}@${TEST_SERVER}:${REMOTE}
	sudo cp ${APP} /usr/local/sbin/pipe.pl
