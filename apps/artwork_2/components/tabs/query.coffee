module.exports = """
  fragment tabs on Artwork {
    series
    publisher
    manufacturer
    signature
    provenance(format: HTML)
    description(format: HTML)
    additional_information(format: HTML)
    exhibition_history(format: HTML)
    bibliography: literature(format: HTML)
  }
"""
