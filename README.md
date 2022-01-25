This is an **UNOFFICIAL** wrapper for the kdecole api

# How to use ?

## Login

First, you need to create a Client() object : <br>

### **LOGIN AND PASSWORD ARE NOT YOUR ENT ONES. TEMPORARY USERNAME AND PASSWORD GIVEN TO INIT THE MOBILE APP SHALL BE USED**

````dart
var client = Client(Urls.<your CAS>, 'your username', 'your password');
````

or if you already have a token :

````dart
var client = Client.fromToken('tokennnnnn', Urls.<your CAS>);
````

Now you're logged in !

To logout :

````dart
await client.logout();
````

## Messaging

### Get the mail box

Of course, you need to have a Client() object, <br>
Next, just get an email list :

````dart
var list = await client.getEmails();
````

It returns you a list of emails which first lines of the first message can be seen. This contains the id, the expeditor
and the receivers.
**WARNING** you can't get the full messages body by this way

### Get details of an email

From your email object, you just need to do :

````dart
await client.getFullEmail(youremail);
````

It will return you another email which contains all the data from the given one, plus the whole discussion, in a list of
Message objects

### The message object

You can get from it :

- The sender
- The date
- The message

## Homeworks

### Get the homeworks

As well as the messaging, this method only return you the first lines of the homework :

```dart
var homeworksList = await client.getHomeworks;
```

It will return you a list of homeworks

### Get the full homework

```dart
var hw = await client.getFullHomework(oldHw);
```

It will return you the new Hw with the full body

### Homework object

You can get from it :

- The content
- The type
- The subject
- The estimated time (if given by the professor)
- The status (is realised)
- The uuid
- The uuid of the session
- the Date

## Timetable

### Get the timetable

There is only one method : 
```dart
var tt = await client.getTimetable();
```

It will return to you a list of Course

### The course object

You can get from it :
- The subject
- A list of homeworks (only theuid, just get the sessionUid and use the getFullHomework method)
- The content (if given)
- The start date (Datetime)
- The end date (Datetime too)
