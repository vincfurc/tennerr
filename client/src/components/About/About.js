import React from "react";
import { Box, Container, Heading, Hero } from 'react-bulma-components';

export default function About() {
    return <div>
                <Container>
                <Box>
        <Hero>
            <Hero.Header>

            </Hero.Header>
            <Hero.Body>
                <Heading>
                    About Tenner
                </Heading>
                <Container>
                    <p>Tennerr is a project for the HackMoney 2021 Virtual DeFi Hackathon.</p>
                    <p><a href='https://github.com/vfurci200/tennerr'>✨Click here for our GitHub ✨</a></p>
                </Container>
            </Hero.Body>
        </Hero>
        </Box>
        </Container>
       
            
        


    </div>;
}
