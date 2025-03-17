import pytest
from thespian.actors import *
from app.thespian.hello import Hello, say_hello

def test_hello_actor():
    system = ActorSystem()
    try:
        hello_actor = system.createActor(Hello)
        response = system.ask(hello_actor, "test", 1.0)
        assert response == "Hello, test!"
    finally:
        system.shutdown()

def test_say_hello_default(capsys):
    say_hello()
    captured = capsys.readouterr()
    assert "Hello, world!" in captured.out

def test_say_hello_with_name(capsys):
    system = ActorSystem()
    try:
        say_hello("Alice")
    finally:
        system.shutdown()
    captured = capsys.readouterr()
    assert "Hello, Alice!" in captured.out
