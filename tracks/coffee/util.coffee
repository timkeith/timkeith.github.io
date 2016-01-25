module.exports =
  getUrl: (path) -> "/tracks/#{path.replace(/^\//, '')}"
