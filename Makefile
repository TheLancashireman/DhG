#! Makefile for DhG
#
# DhG doesn't need to be compiled. This file just contains a rule for creating a release.

FILELIST += Dh_FileList.pm
FILELIST += DhG
FILELIST += Dh_GBrowse.pl
FILELIST += Dh_GCard.pm
FILELIST += Dh_GDump.pl
FILELIST += Dh_GHtml.pm
FILELIST += Dh_GText.pm
FILELIST += gpl-3.0.txt
FILELIST += templates/ahnentafel-html.tmpl
FILELIST += templates/descendant-tree-html.tmpl
FILELIST += templates/descendant-tree-text.tmpl
FILELIST += templates/person-card-html.tmpl
FILELIST += templates/person-card-text.tmpl
FILELIST += templates/person-card.tmpl
FILELIST += templates/person-family-text.tmpl

.PHONY: release

release:	dhg.tar.gz

dhg.tar.gz:	$(FILELIST)
	tar czvf dhg.tar.gz $(FILELIST)

