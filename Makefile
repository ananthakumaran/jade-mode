BATCH=emacs --batch -q -no-site-file \
	--eval="(add-to-list 'load-path \".\")"

all: jade-mode.elc

%.elc: %.el
	$(BATCH) -f batch-byte-compile $<

clean:
	rm -rf *.elc
