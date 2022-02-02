import tippy from 'tippy.js';
import {
  NodeViewContent,
  NodeViewWrapper,
  ReactNodeViewRenderer,
  ReactRenderer,
} from '@tiptap/react';
import React, {
  useState,
  useEffect,
  forwardRef,
  useImperativeHandle,
} from 'react';
import { useSearchUsers } from '..';
import { Loading, Menu } from '@supabase/ui';
import Mention from '@tiptap/extension-mention';
import User from './User';

const MentionList = forwardRef((props: any, ref) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const query = useSearchUsers(props.query);

  useEffect(() => setSelectedIndex(0), [query.data]);

  const selectItem = (index: number) => {
    const item = query.data?.[index];

    if (item) {
      props.command({ id: item.id, label: item.name });
    }
  };

  const upHandler = () => {
    if (!query.data) {
      return;
    }
    setSelectedIndex(
      (selectedIndex + query.data.length - 1) % query.data.length
    );
  };

  const downHandler = () => {
    if (!query.data) {
      return;
    }
    setSelectedIndex((selectedIndex + 1) % query.data.length);
  };

  const enterHandler = () => {
    selectItem(selectedIndex);
  };

  useImperativeHandle(ref, () => ({
    onKeyDown: ({ event }: any) => {
      if (event.key === 'ArrowUp') {
        upHandler();
        return true;
      }

      if (event.key === 'ArrowDown') {
        downHandler();
        return true;
      }

      if (event.key === 'Enter') {
        enterHandler();
        return true;
      }

      return false;
    },
  }));

  return (
    <Menu className="overflow-hidden rounded-lg dark:bg-neutral-800/90 bg-neutral-100/90">
      {query.isLoading && <Loading active>{null}</Loading>}
      {query.data &&
        query.data.length > 0 &&
        query.data.map((item: any, index: number) => (
          <Menu.Item
            active={selectedIndex === index}
            key={index}
            onClick={() => selectItem(index)}
          >
            <User key={item.id} id={item.id} size="sm" propagateClick={false} />
          </Menu.Item>
        ))}
      {query.data && query.data.length === 0 && (
        <div className="px-4 py-2">No result</div>
      )}
    </Menu>
  );
});

export const suggestionConfig = {
  items: () => [],
  render: () => {
    let reactRenderer: any;
    let popup: any;

    return {
      onStart: (props: any) => {
        reactRenderer = new ReactRenderer(MentionList, {
          props,
          editor: props.editor,
        });

        popup = tippy('body', {
          getReferenceClientRect: props.clientRect,
          appendTo: () => document.body,
          content: reactRenderer.element,
          showOnCreate: true,
          interactive: true,
          trigger: 'manual',
          placement: 'bottom-start',
        });
      },
      onUpdate(props: any) {
        reactRenderer.updateProps(props);

        popup[0].setProps({
          getReferenceClientRect: props.clientRect,
        });
      },
      onKeyDown(props: any) {
        return reactRenderer.ref?.onKeyDown(props);
      },
      onExit() {
        popup[0].destroy();
        reactRenderer.destroy();
      },
    };
  },
};

const MentionsExtension = Mention.configure({
  HTMLAttributes: {
    class: 'mention',
  },
  suggestion: suggestionConfig,
});

export default MentionsExtension;
