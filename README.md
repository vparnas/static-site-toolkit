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
	- Category-based indexes
	- [twtxt](https://twtxt.readthedocs.io/) feed
- Generate an RSS feed using the metadata summary or the first html paragraph for the item description.
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
1. Place `.ssg_config` in the project directory with minimally the following variables defined:

    ```conf
    SITE_TITLE="My site"
    INPUTDIR=web
    PROD_OUT=web-prod
    TEMPLATE_DIR=templates
    FEED_RSS=feeds/rss.xml
    PROD_BASE_URL="https://ntmlabs.com"
    ```

Generate a CSV of all html/markdown content in the appropriate format.  Read the appropriate metadata tags for markdown content.  Modify the generated `all-content.csv` appropriately if missing certain metadata. Feel free to amend or modify the file, but if you choose to rerun the following command, your changes will be overwritten.

```sh
idxgen -c web > all-content.csv
```

<a title="index-template" />
Generate an index file that lists all dated entries in a "rolling blog" sense:

```sh
idxgen -x all-content.csv templates/index.html > web/index.html
```

Generate a sitemap:

```sh
idxgen -x all-content.csv templates/sitemap.xml > web/sitemap.xml
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
    FEED_RSS=feeds/rss.xml
    PROD_OUT=web-prod
    PROD_BASE_URL="https://ntmlabs.com"
    ```
1. Execute the following:

```sh
idxgen -r all-content.csv > web/feeds/rss.xml
```

## Optional configuration

```conf
FAV_ICON=icon.png
FEED_RSS=feeds/rss.xml
MENU=( "/projects/" "Projects"\
        "/categories/" "Categories"\
        "/contact/" "Contact"\
        "/feeds/rss.xml" "RSS"\
     )
HEADER="web/_custom-hdr.html"
FOOTER="web/_custom-ftr.html"
```
