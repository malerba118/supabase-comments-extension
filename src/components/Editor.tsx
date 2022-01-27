import React, { FC, ReactNode } from 'react';
import { IconBold, IconCode, IconItalic } from '@supabase/ui';
import { useEditor, EditorContent } from '@tiptap/react';
import clsx from 'clsx';
import Link from '@tiptap/extension-link';
import StarterKit from '@tiptap/starter-kit';
import MentionsExtension from './Mentions';
import Placeholder from '@tiptap/extension-placeholder';
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight';

import styles from './Editor.module.css';
// @ts-ignore
import { lowlight } from 'lowlight';

interface EditorProps {
  defaultValue: string;
  onChange?: (value: string) => void;
  readOnly?: boolean;
  autoFocus?: boolean;
  actions?: ReactNode;
}

const Editor: FC<EditorProps> = ({
  defaultValue,
  onChange,
  readOnly = false,
  autoFocus = false,
  actions = null,
}) => {
  const editor = useEditor({
    editable: !readOnly,
    extensions: [
      StarterKit,
      Placeholder.configure({
        placeholder: 'Write a message...',
      }),
      MentionsExtension,
      CodeBlockLowlight.configure({ lowlight, defaultLanguage: null }),
      Link.configure({
        HTMLAttributes: {
          class: 'tiptap-link',
        },
        openOnClick: false,
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
    <div
      className={clsx(
        readOnly ? styles.viewer : styles.editor,
        'tiptap-editor'
      )}
    >
      <EditorContent
        className={clsx('h-full', readOnly ? null : 'pb-8')}
        editor={editor}
      />
      {!readOnly && (
        <div
          className={clsx(
            styles.actionsBar,
            'absolute bottom-0 left-0 right-0 flex items-center h-8'
          )}
        >
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleBold().run();
              e.preventDefault();
            }}
          >
            <IconBold
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('bold') && 'bg-green-300'
              )}
            />
          </div>
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleItalic().run();
              e.preventDefault();
            }}
          >
            <IconItalic
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('italic') && 'bg-green-300'
              )}
            />
          </div>
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleCodeBlock().run();
              e.preventDefault();
            }}
          >
            <IconCode
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('codeBlock') && 'bg-green-300'
              )}
            />
          </div>
          <div className="flex-1" />
          <div>{actions}</div>
        </div>
      )}
    </div>
  );
};

export default Editor;
