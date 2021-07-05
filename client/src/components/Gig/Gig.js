import React from 'react'
import {Card, Content, Form, Heading, Image, Media, Section} from "react-bulma-components";

export default function Gig() {
    return (
        <Section>
            <form>
                <Form.Field>
                    <Form.Control>
                        <Form.Input type="text" placeholder="Search gigs" />
                    </Form.Control>
                </Form.Field>
            </form>
            <Card>
                <Card.Header>
                    <Card.Header.Title>Recently Added Gigs</Card.Header.Title>
                </Card.Header>
                <Card.Content>
                    <Media>
                        <Media.Item renderAs="figure" position="left">
                            <Image
                                size={64}
                                alt="64x64"
                                src="https://cdn.discordapp.com/avatars/231822195871973376/6df32e924eb3fb95024204c58c4b86fd.png?size=128"
                            />
                        </Media.Item>
                        <Media.Item>
                            <Heading size={4}>iso</Heading>
                            <Heading subtitle size={6}>
                                @iso#0001
                            </Heading>
                        </Media.Item>
                    </Media>
                    <Content>
                        <p>can someone please feed my cats while i'm on vacation this week</p>
                        <p>Payment: 0.0091 Eth per day</p>
                        <time dateTime="2021-7-3">11:09 PM - 3 Jul 2021</time>
                    </Content>
                </Card.Content>
                <Card.Footer>
                    <Card.Footer.Item renderAs="a" href="#Yes">
                        Accept Job
                    </Card.Footer.Item>
                    <Card.Footer.Item renderAs="a" href="#No">
                        No
                    </Card.Footer.Item>
                    <Card.Footer.Item renderAs="a" href="#Maybe">
                        Maybe
                    </Card.Footer.Item>
                </Card.Footer>
            </Card>
        </Section>
    )
}
