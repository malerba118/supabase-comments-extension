import { generateJSON } from '@tiptap/html';
import StarterKit from '@tiptap/starter-kit';
import MentionsExtension from './components/Mentions';
import traverse from 'traverse';

export const getMentionedUserIds = (doc: string): string[] => {
  const userIds: string[] = [];
  const json = generateJSON(doc, [StarterKit, MentionsExtension]);
  traverse(json).forEach(function (node) {
    if (node?.type === 'mention') {
      userIds.push(node.attrs.id);
    }
  });
  return userIds;
};
