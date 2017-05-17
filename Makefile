OUT=www

web:
	./generate.pl --domain=https://kl.cz --out=$(OUT)

clean:
	rm -rf $(OUT)
