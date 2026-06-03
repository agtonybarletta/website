# website
Personal website

## Builds

Github builds include an automatic www.agtonybarletta.it/health check, and, if 
healhty, redirect to www.agtonybarletta.it, otherwise serve the page
```
$ HUGO_ENV="github" hugo build
```

Local build doesn't include this automatic check
```
$ HUGO_ENV="local" hugo build
```