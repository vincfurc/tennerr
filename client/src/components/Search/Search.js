import React from 'react';
import { Block, Box, Form, Heading, Tile } from 'react-bulma-components'

export default function Search() {
    return (
        <div>
            <form>
                <Form.Field>
                    <Form.Control>
                        <Form.Input type="text" placeholder="Search for a job or freelancer" />
                    </Form.Control>
                </Form.Field>
            </form>
            <Block>
            <Tile kind="ancestor" style={{flexWrap: 'wrap'}}>
                    <Tile kind="parent" size={3}>
                        <Tile kind="child" color="primary">
                            <Box>
                                <Heading>vinc</Heading>
                            </Box>
                        </Tile>
                    </Tile>
                    <Tile kind="parent" size={3}>
                        <Tile kind="child" color="primary">
                            <Box>
                                <Heading>eurv</Heading>
                            </Box>
                        </Tile>
                    </Tile>
                    <Tile kind="parent" size={3}>
                        <Tile kind="child" color="primary">
                            <Box>
                                <Heading>iso</Heading>
                            </Box>
                        </Tile>
                    </Tile>
                </Tile>
            </Block>

        </div>
    )
}
