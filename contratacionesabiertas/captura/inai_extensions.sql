
/***
 * RequestForQuotes
 ***/

drop table if exists RequestForQuotes cascade;
create table RequestForQuotes(
id serial primary key
title text,
description text,
period_startdate timestamp,
period_enddate timestamp,
);

drop table if exists RequestForQuotesItems cascade;
create table RequestForQuotesItems(
id serial primary key,
requestforquotes_id integer references RequestForQuotes(id) on delete cascade
/*incluir campos*/
);

drop table ir exists RequestForQuotesPossibleSuppliers cascade;
create table RequestForQuotesPossibleSuppliers(
id serial primary key,
requestforquotes_id integer references RequestForQuotes(id) on delete cascade,
parties_id integer references Parties(id)
);

drop table Quotes cascade;
create table Quotes(
id serial primary key,
requestforquotes_id integer references RequestForQuotes(id) on delete cascade
/* incluir campos */
);

drop table QuotesItems cascade;
create table QuotesItems(
id serial primary key,
quotes_id integer references Quotes(id) on delete cascade
/*incluir campos*/
);

/***
 * ClarificationMeetings
 ***/

drop table ClarificationMeeting cascade;
create table ClarificationMeeting(
id serial primary key,
date timestamp
);

create table attendees(
id serial primary key,
clarificationmeeting_id integer references ClarificationMeeting(id) on delete cascade,
parties_id integer references Parties(id)
);

create table officials(
id serial primary key,
clarificationmeeting_id integer references ClarificationMeeting(id) on delete cascade,
parties_id integer references Parties(id)
);

