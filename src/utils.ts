import { generateJSON } from '@tiptap/html';
import Link from '@tiptap/extension-link';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight';
import MentionsExtension from './components/Mentions';
import traverse from 'traverse';

export const getMentionedUserIds = (doc: string): string[] => {
  const userIds: string[] = [];
  const json = generateJSON(doc, [
    StarterKit,
    Placeholder,
    MentionsExtension,
    CodeBlockLowlight,
    Link,
  ]);
  traverse(json).forEach(function (node) {
    if (node?.type === 'mention') {
      userIds.push(node.attrs.id);
    }
  });
  return userIds;
};
