import tippy from 'tippy.js';
import { ReactRenderer } from '@tiptap/react';
import React, { useState, useEffect, forwardRef } from 'react';
import { useSearchUsers } from '..';
import { Loading, Menu } from '@supabase/ui';

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

  // const upHandler = () => {
  //   setSelectedIndex(
  //     (selectedIndex + query.data.length - 1) % query.data.length
  //   );
  // };

  // const downHandler = () => {
  //   setSelectedIndex((selectedIndex + 1) % query.data.length);
  // };

  // const enterHandler = () => {
  //   selectItem(selectedIndex);
  // };

  // useImperativeHandle(ref, () => ({
  //   onKeyDown: ({ event }: any) => {
  //     if (event.key === "ArrowUp") {
  //       upHandler();
  //       return true;
  //     }

  //     if (event.key === "ArrowDown") {
  //       downHandler();
  //       return true;
  //     }

  //     if (event.key === "Enter") {
  //       enterHandler();
  //       return true;
  //     }

  //     return false;
  //   },
  // }));

  if (query.isLoading) {
    return <Loading active>{null}</Loading>;
  }

  return (
    <Menu className="overflow-hidden bg-gray-100 rounded-lg">
      {query.isLoading && <Loading active>{null}</Loading>}
      {query.data &&
        query.data.length > 0 &&
        query.data.map((item: any, index: number) => (
          <Menu.Item key={index} onClick={() => selectItem(index)}>
            {item.name}
          </Menu.Item>
        ))}
      {query.data && query.data.length === 0 && <div>No result</div>}
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
