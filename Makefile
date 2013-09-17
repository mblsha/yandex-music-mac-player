YandexMusicMacPlayer.dmg:
	mkdir -p tmp
	rsync -a ~/Library/Developer/Xcode/DerivedData/YandexMusic-*/Build/Products/Debug/YandexMusic.app tmp/
	mv tmp/YandexMusic.app tmp/Yandex\ Music\ Player.app
	dmg/pkg-dmg \
	    --verbosity 2 \
	    --volname "Yandex Music Player" \
	    --source tmp/Yandex\ Music\ Player.app \
	    --sourcefile \
	    --target YandexMusicMacPlayer.dmg \
	    --icon tmp/Yandex\ Music\ Player.app/Contents/Resources/app.icns  \
	    --copy dmg/mozilla.dsstore:.DS_Store \
	    --mkdir .background \
	    --copy dmg/mozilla-background.jpg:.background/backgroundImage.jpg \
	    --symlink  /Applications:Applications \
	    --attribute V:.background \
	    --idme
	rm -rf tmp/Yandex\ Music\ Player.app
	rmdir tmp
