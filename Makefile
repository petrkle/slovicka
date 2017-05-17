OUT=www

help:
	@echo "help     - this help"
	@echo "web      - generate web"

web:
	rm -rf $(OUT)
	./generate.pl --domain=https://kl.cz --out=$(OUT)
