# Release procedure
# =================
#
# $ git tag -l
# $ git tag VERSION_HERE
# $ make
# $ make upload
# $ git log -p origin/master..
# $ git push --tags origin master:master
#
# Process logs and print download counter
# =======================================
#
# $ make downloads

VER = $(shell git describe --tags)
BAREVER = $(shell echo $(VER) | tail -c+2)
DMG107 = YandexMusicMacPlayer-$(VER)-10.7.dmg
DMG108 = YandexMusicMacPlayer-$(VER)-10.8.dmg
LASTTAG = $(shell git describe --abbrev=0 --tags)
LASTTAGDATE = $(shell git log -1 --format=%ad --date=short $(LASTTAG))

dmg:
	if [ -a $(DMG107) ] ; \
	then \
	    echo error: $(DMG107) already exists ; \
	    exit 1 ; \
	else \
	    make dmgver VER=$(VER) OSVER=10.7; \
	fi ; \
	if [ -a $(DMG108) ] ; \
	then \
	    echo error: $(DMG108) already exists ; \
	    exit 1 ; \
	else \
	    make dmgver VER=$(VER) OSVER=10.8 ; \
	fi

# usage: make dmgver VER=v0.2.0 OSVER=10.7
dmgver: YandexMusicMacPlayer.dmg
	mv YandexMusicMacPlayer.dmg YandexMusicMacPlayer-$(VER)-$(OSVER).dmg

YandexMusicMacPlayer.dmg: build/Release/YandexMusic.app
	mv build/Release/YandexMusic.app build/Release/Yandex\ Music\ Player.app
	dmg/pkg-dmg \
	    --verbosity 2 \
	    --volname "Yandex Music Player" \
	    --source build/Release/Yandex\ Music\ Player.app \
	    --sourcefile \
	    --target YandexMusicMacPlayer.dmg \
	    --icon build/Release/Yandex\ Music\ Player.app/Contents/Resources/app.icns  \
	    --copy dmg/mozilla.dsstore:.DS_Store \
	    --mkdir .background \
	    --copy dmg/mozilla-background.jpg:.background/backgroundImage.jpg \
	    --symlink  /Applications:Applications \
	    --attribute V:.background \
	    --idme
	rm -rf build/Release/Yandex\ Music\ Player.app

build/Release/YandexMusic.app:
	xcodebuild MACOSX_DEPLOYMENT_TARGET=$(OSVER)

upload:
	git diff --exit-code README.markdown
	@if [ $(LASTTAG) != $(VER) ] ; then \
	    echo error: last commit not tagged ; \
	    exit 1 ; \
	fi
	s3cmd put -P $(DMG107) s3://YandexMusicMacPlayer
	s3cmd put -P $(DMG108) s3://YandexMusicMacPlayer
	sed -i -e 's/\(\[changelog\]: .*\/compare\/\)\(.*\)\.\.\.\(.*\)/\1\3\.\.\.$(VER)/' README.markdown
	sed -i -e 's/\(\[10\.7\]: http.*\/\).*/\1$(DMG107)/' README.markdown
	sed -i -e 's/\(\[10\.8\]: http.*\/\).*/\1$(DMG108)/' README.markdown
	sed -i -e 's/\(#### Latest release\) (.*)/\1 ($(BAREVER), $(LASTTAGDATE))/' README.markdown
	git commit -m 'update download links to $(VER)' README.markdown

downloads:
	mkdir -p logs/
	scripts/process-s3-logs
	scripts/show-downloads | grep GET | wc -l

clean:
	xcodebuild clean
	rm -rf build

.PHONY: dmg clean upload updatelinks
