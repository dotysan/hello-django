SHELL:= /usr/bin/env bash

PY:= python3.12
DJANGO_VER:= 5.1.*
PSYCOPG_VER:= 3.2.*
VENV:= .venv

vb:= $(VENV)/bin
sp:= $(VENV)/lib/$(PY)/site-packages

HERE:= $(notdir $(CURDIR))
PROJECT:= project
APP:= app1

define vrun
	@source $(vb)/activate && $(1)
endef

.SILENT: $(APP)
.SILENT: $(PROJECT)/settings.py
.SILENT: .git

.PHONY: docker
.PHONY: clean

docker: $(APP)
# TODO: after changing database from sqlite to postgres...
#	./manage.py migrate
#	./manage.py createsuperuser --username=foo --email=bar@baz.com
#	$(call vrun,./manage.py runserver)
	git push

$(APP): $(PROJECT)/settings.py
	$(call vrun,./manage.py startapp $(APP))

	git add $(APP)
	git commit -m './manage.py startapp $(APP)'
	touch $@

$(PROJECT)/settings.py: $(vb)/django-admin .git
	$(call vrun,django-admin startproject $(PROJECT) .)
	$(call vrun,./key2env.py $(PROJECT))
	direnv allow  # assumes you have direnv hooked into your shell

	git add $(PROJECT) manage.py
	git commit -m 'django-admin startproject $(PROJECT) .'
	touch $@


.git:
	-gh repo delete $(HERE)
	-gh repo create $(HERE) --description=$(HERE) --public \
		--clone --license=mit --add-readme --gitignore=Python

	mv --no-clobber $(HERE)/.git ./
	mv --no-clobber $(HERE)/.gitignore ./
	mv --no-clobber $(HERE)/LICENSE ./
	mv --no-clobber $(HERE)/README.md ./
	rmdir $(HERE)

	git add Makefile
	git commit -m 'Add this Makefile'

	sed -i '/^\.env$$/a\.envrc' .gitignore
	git add key2env.py .gitignore .flake8
	flake8 key2env.py
	git commit -m 'Add script to move secrets out of settings'


$(vb)/django-admin: $(vb)/pip $(sp)/psycopg_binary
	$(call vrun,pip install Django==$(DJANGO_VER))

$(sp)/psycopg_binary: $(vb)/pip
	$(call vrun,pip install psycopg[binary]==$(PSYCOPG_VER))

$(vb)/pip: $(vb)/activate
	$(call vrun,pip list --format=freeze |grep -oE '^[^=]+' \
		|xargs pip install --upgrade)

$(vb)/activate:
	$(PY) -m venv $(VENV)

clean:
	rm -fr $(VENV) $(PROJECT) manage.py .envrc
