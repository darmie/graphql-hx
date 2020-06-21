#!/bin/sh
rm -f GraphQL.zip
zip -r GraphQL.zip src *.hxml *.json *.md run.n
haxelib submit GraphQL.zip $HAXELIB_PWD --always