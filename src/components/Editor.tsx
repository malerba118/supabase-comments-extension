import React, { FC } from 'react';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { suggestionConfig } from './Mentions';
import Mention from '@tiptap/extension-mention';
import styles from './Editor.module.css';
import clsx from 'clsx';

interface EditorProps {
  defaultValue: string;
  onChange?: (value: string) => void;
  readOnly?: boolean;
  autoFocus?: boolean;
}

const Editor: FC<EditorProps> = ({
  defaultValue,
  onChange,
  readOnly = false,
  autoFocus = false,
}) => {
  const editor = useEditor({
    editable: !readOnly,
    extensions: [
      StarterKit,
      Mention.configure({
        HTMLAttributes: {
          class: 'mention',
        },
        suggestion: suggestionConfig,
      }),
    ],
    content: defaultValue,
    onUpdate: ({ editor }) => {
      onChange?.(editor.getHTML());
    },
    autofocus: autoFocus ? 'end' : false,
    editorProps: {
      attributes: {
        class: 'tiptap-editor',
      },
    },
  });

  return (
    <div className={clsx(styles.container, readOnly ? styles.readOnly : null)}>
      <EditorContent className={styles.editor} editor={editor} />
    </div>
  );
};

export default Editor;
