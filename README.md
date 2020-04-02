# static-site-toolkit

## Description 

Tools to streamline the publishing of static web content.

## Goals

1. Minimize external dependencies. 
1. Leverage available tools to the greatest extent possible: sed, awk, grep, sort, Make, shell
1. Don't use python. Too slow for my taste.
1. Transcend the limitations of the simpler tools such as [saait](https://git.codemadness.org/saait), [sw](https://github.com/jroimartin/sw), [ssg5](https://www.romanzolotarev.com/ssg.html) (from which this is partially derived), and yet avoid the complexity of [Pelican](https://github.com/getpelican).

## Features

- Develop plain html or markdown content. Uses [lowdown](https://kristaps.bsd.lv/lowdown/) to compile the markdown.
- Leverage the markdown metadata to populate your pages, with or without the *yaml* surrounding delimiters.
- Global header and footer templates for all content.
- Generate *indexed* content from special header/footer/body templates, respecting the above *global* header and footer. The index templates, similarly, support site and metadata originating variables. (Inspired by *saait*.) Examples:
    - Dated index/archive pages.
    - Sitemap
    - RSS feed
    - Category-based indexes
    - [twtxt](https://twtxt.readthedocs.io/) feed
- Populate the RSS description field with the metadata summary or the first html paragraph
- In the header template, leverage metadata fields as well as the site configured variables. 
- Support for conditional sections in the header template.
- Transform all `.../page.md` markdown content to a format `.../page/index.html`. Respect all other naming convention and the flexibility of any web directory hierarchy.
- Allow symbolically linked content in the source directory. 
- Only build new or updated content.

## Requirements

- [lowdown](https://kristaps.bsd.lv/lowdown/)
- cpio
- Make

## Usage

1. Pick a directory for your project. You will execute all the below commands from here.
1. Create a subdirectory `web`.  Place your markdown, html bodies, `_header.html`, `_footer.html` here.
1. Create a subdirectory `web-prod`. Your compiled and production content will go here.
1. Create a subdirectory `templates` for any index templates you may want. See [below](#index-template)
1. Place `.ssg_config` in the project directory with *minimally* the following variables defined:

    ```conf
    SITE_TITLE="My site"
    FEED_RSS=/feeds/rss.xml
    ```

Generate a CSV of all html/markdown content in the appropriate format.  Read the appropriate metadata tags for markdown content.  Modify the generated `all-content.csv` appropriately if missing certain metadata. Feel free to amend or modify the file, but if you choose to rerun the following command, your changes will be overwritten.

```sh
idxgen -c web > all-content.csv
```

<a title="index-template" />
Generate an index file that lists all dated entries in a "rolling blog" sense:

```sh
idxgen -x all-content.csv web/index.html templates/index.html
```

Generate a sitemap:

```sh
idxgen -x all-content.csv web/sitemap.xml templates/sitemap.xml
```

Compile your static content as well as any indexes from above. This converts all markdown to html and joins the appropriate headers/footers.

```sh
ssg5 web web-prod "My site" "https://ntmlabs.com"
```

### Generate an rss feed:

1. Insure your production (compiled) content already exists in `$PROD_OUT`.
1. Assert the following variables in `.ssg_config`, needed for a complete RSS.

    ```conf
    SITE_TITLE="My site"
    FEED_RSS=/feeds/rss.xml
    PROD_OUT=web-prod
    PROD_BASE_URL="https://ntmlabs.com"
    ```
1. Make sure the `templates` folder contains `rss.xml`, `rss.hdr` and `rss.ftr`.
1. Execute the following:

```sh
idxgen -x all-content.csv web/feeds/rss.xml templates/feeds/rss.xml
```

## Automating the build

The `examples` subfolder contains a Makefile useful to automate the build process. This requires a more complete configuration set:

```conf
SITE_TITLE="My site"
INPUTDIR=web
DEV_OUT=web-dev
PROD_OUT=web-prod
TEMPLATE_DIR=templates
URL_LIST=all_content.csv
FEED_RSS=/feeds/rss.xml
DEV_BASE_URL="http://localhost:8080"
PROD_BASE_URL="https://mysite.com"
```

1. Run `make` to generate the *URL_LIST*, build all the templates and compile a local website in *DEV_OUT*.
1. Run `make prod` to similarly build the production version in *PROD_OUT*
1. Optional: if S3_BUCKET is defined (see below), execute `make s3_upload` to sync the *PROD_OUT* folder with the appropriate Amazon S3 bucket.

## Optional configuration

```conf
FAV_ICON=icon.png
SHORT_INDEXES=index.html # index template that produces only the latest 10 posts
HEADER="web/_custom-hdr.html"
FOOTER="web/_custom-ftr.html"
# Set to the Amazon S3 bucket hosting your web content, *excluding* the s3:// portion. Comment out to omit the Makefile S3 uploading logic.
S3_BUCKET= 
```
