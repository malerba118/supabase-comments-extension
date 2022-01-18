import { FC, useMemo } from "react";
import ReactTimeAgo from "react-time-ago";
import _TimeAgo from "javascript-time-ago";
import en from "javascript-time-ago/locale/en.json";

_TimeAgo.addDefaultLocale(en);

interface TimeAgoProps {
  date: string | Date;
  locale: string;
}

const TimeAgo: FC<TimeAgoProps> = ({ date, locale = "en-US" }) => {
  const _date = useMemo(() => new Date(date), [date]);

  return <ReactTimeAgo date={_date} locale={locale} timeStyle="mini-now" />;
};

export default TimeAgo;
