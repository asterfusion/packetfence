CC = g++
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -lpcap

TARGET = udp_reflector
SRC = source/udp_reflector.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

install:
	install -D -m 0755 $(TARGET) $(DESTDIR)/usr/bin/$(TARGET)
	install -D -m 0644 service/udp-reflector.service $(DESTDIR)/lib/systemd/system/udp-reflector.service

clean:
	rm -f $(TARGET)

.PHONY: all install clean