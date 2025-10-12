package tools.vitruv.dsls.reactions.tests.maturity

import com.google.inject.Inject
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import tools.vitruv.dsls.reactions.language.toplevelelements.MaturityLevelEnum
import tools.vitruv.dsls.reactions.language.toplevelelements.Reaction
import tools.vitruv.dsls.reactions.language.toplevelelements.ReactionsFile
import tools.vitruv.dsls.reactions.tests.ReactionsLanguageInjectorProvider
import allElementTypes.AllElementTypesPackage
import static org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(ReactionsLanguageInjectorProvider)
class ReactionWithMaturityGeneratorTest {
    @Inject extension ValidationTestHelper
    @Inject extension ParseHelper<ReactionsFile>
    @Inject ISerializer serializer

    def private CharSequence headerWithNsUri(String alias) '''
        import "«AllElementTypesPackage.eNS_URI»" as «alias»
        reactions: R
        in reaction to changes in «alias»
        execute actions in «alias»
    '''

    @Test
    def void testParsesSingleValuedMaturityFinal() {
        val reaction = '''
            «headerWithNsUri("aet")»
            reaction MyReaction {
                where maturity FINAL
                after element aet::Root created
                call org.eclipse.xtext.xbase.lib.InputOutput.println("ok")
            }
        '''.parse

        reaction.assertNoErrors
        val rxn = reaction.reactionsSegments.head.reactions.head as Reaction
        assertEquals(MaturityLevelEnum.FINAL, rxn.maturity)

        val text = serializer.serialize(reaction)
        assertTrue(text.contains("where maturity FINAL"))
    }

    @Test
    def void testMaturityDefaultsToDraftWhenOmitted() {
        val reaction = '''
            «headerWithNsUri("aet")»
            reaction MyReaction {
                after element aet::Root created
                call org.eclipse.xtext.xbase.lib.InputOutput.println("ok")
            }
        '''.parse

        reaction.assertNoErrors
        val rxn = reaction.reactionsSegments.head.reactions.head as Reaction
        assertEquals(MaturityLevelEnum.DRAFT, rxn.maturity)

        val text = serializer.serialize(reaction)
        assertFalse(text.contains("where maturity"))
    }

    @Test
    def void testCommaSeparatedMaturityListRejected() {
        val reaction = '''
            «headerWithNsUri("aet")»
            reaction MyReaction {
                where maturity DRAFT, FINAL
                after element aet::Root created
                call org.eclipse.xtext.xbase.lib.InputOutput.println("ok")
            }
        '''.parse

        assertFalse(reaction.eResource.errors.empty)
    }

    @Test
    def void testMaturityInsideTriggerOrAfterCallRejected() {
        val badReaction1 = '''
            «headerWithNsUri("aet")»
            reaction MyReaction {
                after element aet::Root created
                where maturity FINAL
                call org.eclipse.xtext.xbase.lib.InputOutput.println("ok")
            }
        '''.parse
        assertFalse(badReaction1.eResource.errors.empty)

        val badReaction2 = '''
            «headerWithNsUri("aet")»
            reaction MyReaction {
                where maturity FINAL
                after element aet::Root created
                call org.eclipse.xtext.xbase.lib.InputOutput.println("ok")
                where maturity FINAL
            }
        '''.parse
        assertFalse(badReaction2.eResource.errors.empty)
    }

    @Test
    def void testSerializerKeepsMaturityReviewed() {
        val reaction = '''
            «headerWithNsUri("aet")»
            reaction MyReaction {
                where maturity REVIEWED
                after element aet::Root created
                call org.eclipse.xtext.xbase.lib.InputOutput.println("ok")
            }
        '''.parse

        reaction.assertNoErrors
        val text = serializer.serialize(reaction)
        assertTrue(text.contains("where maturity REVIEWED"))
    }
}
