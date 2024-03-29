# MAHDTech Website

This repository contains the source files for [MAHDTech](https://mahdtech.com)

## How to generate new website content

1. Modify the source files
2. Merge into the trunk branch repo
3. Wait for the GitHub Actions to work it's magic
4. Profit, the website is now available via Cloudflare Workers.

## How to add comments

The comments on blog posts are tied to GitHub issues.

For each blog post, create a GitHub issue and add the issue ID to the front matter of the post.

Example post.md

```toml
+++
title = "Interesting blog post"
GitHubIssueId = 1
+++
```

Any comments to that GitHub issue are then loaded automatically onto the website.

A Discord webhook has been configured to post comments in the #CI channel.
