# Procedure
# =========
# Xcode: build
# make
# mv YandexMusicMacPlayer.dmg YandexMusicMacPlayer-v0.2.0-10.7.dmg
# git stash
# Xcode: build
# make
# mv YandexMusicMacPlayer.dmg YandexMusicMacPlayer-v0.2.0-10.8.dmg
# git stash pop
# deploy
# s3cmd put -P YandexMusicMacPlayer-v0.2.0-10.7.dmg s3://YandexMusicMacPlayer
# s3cmd put -P YandexMusicMacPlayer-v0.2.0-10.8.dmg s3://YandexMusicMacPlayer
# update README links (spaces `  ` are important)
# git tag v0.2.0 master
# changelog: https://github.com/mblsha/yandex-music-mac-player/compare/v0.1.0...v0.2.0
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
