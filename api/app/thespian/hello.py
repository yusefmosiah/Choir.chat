from thespian.actors import *

class Hello(Actor):
    def receiveMessage(self, message, sender):
        if isinstance(message, str):
            self.send(sender, f'Hello, {message}!')
        else:
            self.send(sender, 'Hello, world!')

def say_hello(name: str = None):
    system = ActorSystem()
    hello_actor = system.createActor(Hello)
    try:
        # Fix: Use explicit check for None instead of 'or' to preserve empty strings
        message = name if name is not None else 'world'
        response = system.ask(hello_actor, message, 1.5)
        print(response)
    finally:
        system.tell(hello_actor, ActorExitRequest())
        system.shutdown()  # Add explicit shutdown

if __name__ == "__main__":
    import sys
    say_hello(sys.argv[1] if len(sys.argv) > 1 else None)
