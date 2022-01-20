import React, { FC } from 'react';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import MentionsExtension from './Mentions';
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
    extensions: [StarterKit, MentionsExtension],
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
    <div className={clsx(readOnly ? styles.viewer : styles.editor)}>
      <EditorContent className="h-full" editor={editor} />
    </div>
  );
};

export default Editor;
