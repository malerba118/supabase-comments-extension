import { FC } from "react";
import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";

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
    extensions: [StarterKit],
    content: defaultValue,
    onUpdate: ({ editor }) => {
      onChange?.(editor.getHTML());
    },
    autofocus: autoFocus ? "end" : null,
    editorProps: {
      attributes: {
        class: "tiptap-editor",
      },
    },
  });

  return (
    <div>
      <EditorContent editor={editor} />
    </div>
  );
};

export default Editor;