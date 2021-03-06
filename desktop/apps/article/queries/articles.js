import articleBody from 'desktop/apps/article/queries/articleBody'
import sectionFragments from 'desktop/apps/article/queries/sectionFragments'
import relatedArticles from 'desktop/apps/article/queries/relatedArticles'
import { displayFragment, display } from 'desktop/apps/article/queries/display'

export default ({ offset, limit, channel, omit }) => {
  return `
    {
      articles(published: true, channel_id: "${channel}" limit: ${limit}, offset: ${offset}, featured: true, sort: "-published_at", omit: ["${omit}"]) {
        ${articleBody}
        ${relatedArticles}
        ${display}
      }
    }
    ${displayFragment}
    ${sectionFragments}
  `
}
