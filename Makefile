PREFIX  ?= /usr/local
SHARE   ?= /share
BIN     ?= /bin

install:
	mkdir -p $(DESTDIR)/$(PREFIX)/$(BIN)
	mkdir -p $(DESTDIR)/$(PREFIX)/$(SHARE)/gallery
	install -m 555 gallery $(DESTDIR)/$(PREFIX)/$(BIN)
	install -m 444 style.css $(DESTDIR)/$(PREFIX)/$(SHARE)/gallery

uninstall:
	rm -f $(DESTDIR)/$(PREFIX)/$(BIN)/gallery
	rm -rf $(DESTDIR)/$(PREFIX)/$(SHARE)/gallery

