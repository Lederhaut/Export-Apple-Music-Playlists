ALL: exportplaylists

exportplaylists: ExportPlaylists.applescript
	osacompile -o ExportPlaylists.app ExportPlaylists.applescript

deploy: exportplaylists
	mkdir -p ~/Library/Music/Scripts
	mv ExportPlaylists.app ~/Library/Music/Scripts/

clean:
	rm -rfv *.app

clean-deploy:
	rm -rfv ~/Library/Music/Scripts/ExportPlaylists.app
