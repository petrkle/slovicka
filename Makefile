help:
	@echo "help     - this help"
	@echo "web      - generate web"
	@echo "upload   - upload files on web"
	@echo "clean    - remove generated files"


web:
	./generate.pl

upload:
	rsync --rsh=ssh \
		--recursive \
	 	--stats \
		--human-readable \
		--delete-after \
		www/ vps.kle.cz:/home/www/kle.cz/slovicka/

clean:
	rm -rf www
