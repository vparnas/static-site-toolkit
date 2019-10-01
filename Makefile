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
S3_BUCKET?=
DEV_BASE_URL?=
PROD_BASE_URL?=
$(DEV_OUT)_URL=$(DEV_BASE_URL)
$(PROD_OUT)_URL=$(PROD_BASE_URL)

SSG_UPDATE_LIST=.files
LCP_TSTAMP=.lcp_updated
LCP_INPUT=cross-postings.list

S3_DEPS=$(PROD_OUT)/$(SSG_UPDATE_LIST)

.PHONY: default dev prod s3_upload clean 

default: dev

clean:
	rm -rfv $(DEV_OUT) $(PROD_OUT) dummy

%/clear:
	[ -d $(@D) ] && rm -v $(@D)/$(SSG_UPDATE_LIST)

$(URL_LIST): 
	$(PG) -c $(INPUTDIR) > $@

indexes := $(patsubst %, $(INPUTDIR)/%, \
	$(filter-out %.hdr %.ftr rss.% category.%, \
	$(patsubst $(TEMPLATE_DIR)/%, %, \
	$(wildcard $(TEMPLATE_DIR)/*.*))))

# TODO: make each index also dependent on all index.* templates
$(indexes): $(URL_LIST)
	[ -d $(@D) ] || mkdir -p $(@D)
	$(PG) -x $< $(TEMPLATE_DIR)/$(@F) > $@

%/$(SSG_UPDATE_LIST): $(indexes) FORCE
	[ -d $(@D) ] || mkdir -p $(@D)
	$(SSG) $(INPUTDIR) $(@D) $(SITE_TITLE) $($(@D)_URL)

FORCE:

# The RSS feed depends on $(PROD_OUT)/$(SSG_UPDATE_LIST) since the rss routine scans the production content to populate the description.
ifdef FEED_RSS
%/$(FEED_RSS): $(URL_LIST) $(PROD_OUT)/$(SSG_UPDATE_LIST)
	[ -d $(@D) ] || mkdir -p $(@D)
	$(PG) -r $< > $@
endif

ifneq (,$(wildcard ./$(LCP_INPUT)))
%/$(LCP_TSTAMP): %/$(SSG_UPDATE_LIST)
	$(LCP) -r $(@D) -L < $(LCP_INPUT)
S3_DEPS += $(PROD_OUT)/$(LCP_TSTAMP)
endif

dev: $(DEV_OUT)/$(SSG_UPDATE_LIST)

prod: $(PROD_OUT)/$(SSG_UPDATE_LIST)

ifdef FEED_RSS
dev_rss: $(DEV_OUT)/$(FEED_RSS)
prod_rss: $(PROD_OUT)/$(FEED_RSS)
endif

s3_upload: $(S3_DEPS)
	s3cmd sync $(foreach excl,$(notdir $(S3_DEPS)),--exclude='$(excl)') $(PROD_OUT)/ s3://$(S3_BUCKET) --acl-public --delete-removed --guess-mime-type --no-mime-magic --no-preserve --cf-invalidate

