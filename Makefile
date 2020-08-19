SSG=ssg5
PG=idxgen
LCP=link-cross-postings
CFG=.ssg_config

ifneq (,$(wildcard ./$(CFG)))
    include $(CFG)
endif

# The below default values are set only if absent in config
SITE_TITLE?="My website" 
INPUTDIR?=web
TEMPLATE_DIR?=templates
DEV_OUT?=web-dev
PROD_OUT?=web-prod
URL_LIST?=all_pages.csv
FEED_RSS?=
S3_BUCKET?=
SSH_PATH?=
DEV_BASE_URL?=
PROD_BASE_URL?=
$(DEV_OUT)_URL=$(DEV_BASE_URL)
$(PROD_OUT)_URL=$(PROD_BASE_URL)
SHORT_INDEXES?= # index(es) of only the most recent entries

SSG_UPDATE_LIST=.files
LCP_TSTAMP=.lcp_updated
LCP_INPUT=cross-postings.list

UPLOAD_DEPS=$(PROD_OUT)/$(SSG_UPDATE_LIST)

.PHONY: default dev prod s3_upload clean 

default: dev

clean: clean_indexes
	rm -rfv $(DEV_OUT) $(PROD_OUT) dummy
	rm -fv $(URL_LIST)

dev_refresh: clean_indexes
	rm -fv $(DEV_OUT)/$(SSG_UPDATE_LIST)

prod_refresh: clean_indexes
	rm -fv $(PROD_OUT)/$(SSG_UPDATE_LIST)

clean_indexes:
	rm -rfv $(indexes) $(short_indexes) $(INPUTDIR)/categories $(DEV_OUT)/$(FEED_RSS) $(PROD_OUT)/$(FEED_RSS) dummy

$(URL_LIST): 
	mkdir -p $(INPUTDIR)
	$(PG) -c $(INPUTDIR) > $@

# Top latest posts
$(URL_LIST).short: $(URL_LIST)
	$(shell head -11 $(URL_LIST) > $@)

short_indexes := $(patsubst %, $(INPUTDIR)/%, $(SHORT_INDEXES))

indexes := $(patsubst %, $(INPUTDIR)/%, \
	$(filter-out %.hdr %.ftr %rss.xml category.% $(SHORT_INDEXES), \
	$(patsubst $(TEMPLATE_DIR)/%, %, \
	$(shell find $(TEMPLATE_DIR) -type f ))))

# TODO: make each index also dependent on all index.* templates
$(indexes): $(URL_LIST)
	mkdir -p $(@D)
	$(PG) -x $< $@ $(patsubst $(INPUTDIR)/%, $(TEMPLATE_DIR)/%, $@)

$(short_indexes): $(URL_LIST).short
	mkdir -p $(@D)
	$(PG) -x $< $@ $(TEMPLATE_DIR)/$(@F) "" 1

# The RSS feed depends on $(PROD_OUT)/$(SSG_UPDATE_LIST) since the rss routine scans the production content to populate the description.
ifdef FEED_RSS
%/$(FEED_RSS): $(URL_LIST) $(PROD_OUT)/$(SSG_UPDATE_LIST)
	mkdir -p $(@D)
	$(PG) -x $< $@ $(TEMPLATE_DIR)/$(FEED_RSS)

dev_rss: $(DEV_OUT)/$(FEED_RSS)
prod_rss: $(PROD_OUT)/$(FEED_RSS)
endif

%/$(SSG_UPDATE_LIST): $(indexes) $(short_indexes) FORCE
	mkdir -p $(@D)
	$(SSG) $(INPUTDIR) $(@D) $(SITE_TITLE) $($(@D)_URL)

FORCE:

ifneq (,$(wildcard ./$(LCP_INPUT)))
%/$(LCP_TSTAMP): %/$(SSG_UPDATE_LIST)
	$(LCP) -r $(@D) -L < $(LCP_INPUT)
UPLOAD_DEPS += $(PROD_OUT)/$(LCP_TSTAMP)
endif

dev: $(DEV_OUT)/$(SSG_UPDATE_LIST)

prod: $(PROD_OUT)/$(SSG_UPDATE_LIST)

ifdef S3_BUCKET
s3_upload: $(UPLOAD_DEPS)
	s3cmd sync $(foreach excl,$(notdir $(UPLOAD_DEPS)),--exclude='$(excl)') $(PROD_OUT)/ s3://$(S3_BUCKET) --acl-public --delete-removed --guess-mime-type --no-mime-magic --no-preserve --cf-invalidate
endif

ifdef SSH_PATH
ssh_upload: $(UPLOAD_DEPS)
	rsync -avChum --progress --delete $(foreach excl,$(notdir $(UPLOAD_DEPS)),--exclude '$(excl)') $(PROD_OUT)/ $(SSH_PATH) 
endif

###### New post/edit post macros ##########

POSTDIR=$(INPUTDIR)/posts/$(shell date +'%Y/%m')
SLUG := $(shell echo '${NAME}' | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z)
EXT ?= md

newpost:
ifdef NAME
	mkdir -p $(POSTDIR)
	echo "---\n"\
	"Title: $(NAME)\n"\
	"Date: $(shell date +'%Y-%m-%d')\n"\
	"Category: Blog\n"\
	"Status: Published\n"\
	"...\n\n" >> $(POSTDIR)/$(SLUG).$(EXT)
	${EDITOR} ${POSTDIR}/${SLUG}.${EXT}
else
	@echo 'Variable NAME is not defined.'
	@echo 'Do make newpost NAME='"'"'Post Name'"'"
endif

editpost:
ifdef NAME
	find ${INPUTDIR} -type f -iregex '.*${SLUG}.*\.${EXT}' -exec ${EDITOR} {} \+
else
	@echo 'Variable NAME is not defined.'
	@echo 'Do make editpost NAME='"'"'Post Name'"'"
endif

