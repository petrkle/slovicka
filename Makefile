OUT=www

help:
	@echo "help     - this help"
	@echo "web      - generate web"
	@echo "upload   - upload files on web"
	@echo "clean    - remove generated files"


web:
	rm -rf $(OUT)
	./generate.pl

upload:
	rsync --rsh=ssh \
		--recursive \
	 	--stats \
		--human-readable \
		--delete-after \
		$(OUT)/ vps.kle.cz:/home/www/kle.cz/slovicka/

clean:
	rm -rf $(OUT)
