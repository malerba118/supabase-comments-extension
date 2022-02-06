import React, { FC, forwardRef, ReactNode, useImperativeHandle } from 'react';
import { IconBold, IconCode, IconItalic, IconList } from '@supabase/ui';
import { useEditor, EditorContent } from '@tiptap/react';
import clsx from 'clsx';
import Link from '@tiptap/extension-link';
import StarterKit from '@tiptap/starter-kit';
import MentionsExtension from './Mentions';
import Placeholder from '@tiptap/extension-placeholder';
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight';
import { Editor as EditorType } from '@tiptap/core';

import styles from './Editor.module.css';
// @ts-ignore
import { lowlight } from 'lowlight';
import { useCommentsContext } from './CommentsProvider';

interface EditorProps {
  defaultValue: string;
  onChange?: (value: string) => void;
  readOnly?: boolean;
  autoFocus?: boolean;
  actions?: (params: { editor: EditorType | null }) => ReactNode;
}

const Editor: FC<EditorProps> = (
  {
    defaultValue,
    onChange,
    readOnly = false,
    autoFocus = false,
    actions = null,
  },
  ref
) => {
  const context = useCommentsContext();
  const extensions: any[] = [
    StarterKit,
    Placeholder.configure({
      placeholder: 'Write a message...',
    }),
    CodeBlockLowlight.configure({ lowlight, defaultLanguage: null }),
    Link.configure({
      HTMLAttributes: {
        class: 'tiptap-link',
      },
      openOnClick: false,
    }),
  ];
  if (context.enableMentions) {
    extensions.push(MentionsExtension);
  }
  const editor = useEditor({
    editable: !readOnly,
    extensions,
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

  const activeStyles = 'bg-alpha-10';

  return (
    <div
      className={clsx(
        readOnly ? styles.viewer : styles.editor,
        'tiptap-editor text-alpha-80 border-alpha-10 rounded-md'
      )}
    >
      <EditorContent
        className={clsx('h-full', readOnly ? null : 'pb-8')}
        editor={editor}
      />
      {!readOnly && (
        <div
          className={clsx(
            'border-t-2 border-alpha-10',
            'absolute bottom-0 left-0 right-0 flex items-center h-8 z-10'
          )}
        >
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleBold().run();
              e.preventDefault();
            }}
            title="Bold"
          >
            <IconBold
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('bold') && activeStyles
              )}
            />
          </div>
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleItalic().run();
              e.preventDefault();
            }}
            title="Italic"
          >
            <IconItalic
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('italic') && activeStyles
              )}
            />
          </div>
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleCodeBlock().run();
              e.preventDefault();
            }}
            title="Code Block"
          >
            <IconCode
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('codeBlock') && activeStyles
              )}
            />
          </div>
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleBulletList().run();
              e.preventDefault();
            }}
            title="Bullet List"
          >
            <svg
              stroke="currentColor"
              fill="currentColor"
              fillOpacity=".75"
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('bulletList') && activeStyles
              )}
              strokeWidth="0"
              viewBox="0 0 1024 1024"
              height="1em"
              width="1em"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M912 192H328c-4.4 0-8 3.6-8 8v56c0 4.4 3.6 8 8 8h584c4.4 0 8-3.6 8-8v-56c0-4.4-3.6-8-8-8zm0 284H328c-4.4 0-8 3.6-8 8v56c0 4.4 3.6 8 8 8h584c4.4 0 8-3.6 8-8v-56c0-4.4-3.6-8-8-8zm0 284H328c-4.4 0-8 3.6-8 8v56c0 4.4 3.6 8 8 8h584c4.4 0 8-3.6 8-8v-56c0-4.4-3.6-8-8-8zM104 228a56 56 0 1 0 112 0 56 56 0 1 0-112 0zm0 284a56 56 0 1 0 112 0 56 56 0 1 0-112 0zm0 284a56 56 0 1 0 112 0 56 56 0 1 0-112 0z"></path>
            </svg>
          </div>
          <div
            className={'grid w-8 h-full place-items-center cursor-pointer'}
            onMouseDown={(e) => {
              editor?.chain().focus().toggleOrderedList().run();
              e.preventDefault();
            }}
            title="Numbered List"
          >
            <svg
              stroke="currentColor"
              fill="currentColor"
              fillOpacity=".75"
              className={clsx(
                'h-6 w-6 p-1.5 font-bold rounded-full',
                editor?.isActive('orderedList') && activeStyles
              )}
              strokeWidth="0"
              viewBox="0 0 1024 1024"
              height="1em"
              width="1em"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M920 760H336c-4.4 0-8 3.6-8 8v56c0 4.4 3.6 8 8 8h584c4.4 0 8-3.6 8-8v-56c0-4.4-3.6-8-8-8zm0-568H336c-4.4 0-8 3.6-8 8v56c0 4.4 3.6 8 8 8h584c4.4 0 8-3.6 8-8v-56c0-4.4-3.6-8-8-8zm0 284H336c-4.4 0-8 3.6-8 8v56c0 4.4 3.6 8 8 8h584c4.4 0 8-3.6 8-8v-56c0-4.4-3.6-8-8-8zM216 712H100c-2.2 0-4 1.8-4 4v34c0 2.2 1.8 4 4 4h72.4v20.5h-35.7c-2.2 0-4 1.8-4 4v34c0 2.2 1.8 4 4 4h35.7V838H100c-2.2 0-4 1.8-4 4v34c0 2.2 1.8 4 4 4h116c2.2 0 4-1.8 4-4V716c0-2.2-1.8-4-4-4zM100 188h38v120c0 2.2 1.8 4 4 4h40c2.2 0 4-1.8 4-4V152c0-4.4-3.6-8-8-8h-78c-2.2 0-4 1.8-4 4v36c0 2.2 1.8 4 4 4zm116 240H100c-2.2 0-4 1.8-4 4v36c0 2.2 1.8 4 4 4h68.4l-70.3 77.7a8.3 8.3 0 0 0-2.1 5.4V592c0 2.2 1.8 4 4 4h116c2.2 0 4-1.8 4-4v-36c0-2.2-1.8-4-4-4h-68.4l70.3-77.7a8.3 8.3 0 0 0 2.1-5.4V432c0-2.2-1.8-4-4-4z"></path>
            </svg>
          </div>
          <div className="flex-1" />
          <div>{actions?.({ editor })}</div>
        </div>
      )}
    </div>
  );
};
export default Editor;
